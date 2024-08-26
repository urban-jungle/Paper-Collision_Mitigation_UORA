function [result] = CM_UORA(ocwmin, ocwmax)
    CR = 2/3; % coding rate
    GI = 1.6*10^-6; % guard interval
    SD = 12.8*10^-6; % symbol duration
    SS_num = 1; % 1개의 안테나, 1개씩 보냄
    BS = 6; % 64QAM 기준 6
    NR = 9; % RU 개수
    RU_tone = [24 24 24 24 24 24 24 24 24]; % 9-RU: 모든 RU는 26tone RU
    m = 1; % mode
    Sta_num = 10:10:200; % 단말 개수

    Result_Set = zeros(1000, 1000, 10);
    DR = 6.67; % data rate per RU
    SIFS = 16*10^-6;
    U_slot = 9*10^-6;

    Trigger_frame = 100*10^-6; % Trigger frame 길이 (byte)
    PHY_header = 40*10^-6; % PHY헤더 길이 (byte)
    Back = 68*10^-6; % Block ack 길이 (byte)
    slot_num = 1111112*6;

    % 시뮬레이션 반복 시작
    while(m<=1)
    k = 1;
    while (k <= 10) % 몇번 반복 시뮬레이션 할지
        disp(k);
        for idx = 1:length(Sta_num)
            NS = Sta_num(idx); % NS : 단말의 현 시점 개수
            OCWmin = ocwmin;
            OCWmax = ocwmax;
            MPDU_len = 2000*ones(1, NS);

            SR = zeros(NS, 3); % Station Result 배열(접속시도, 성공, 충돌)
            RR = zeros(NR, 3); % RU Result 배열(유휴, 성공, 충돌)
            NT = 0; % trigger frame 개수

            Sta.OCWmin = OCWmin * ones(1, NS);
            Sta.OCWmax = OCWmax * ones(1, NS);
            Sta.OCW = Sta.OCWmax;

            Sta.OBO = floor(Sta.OCW.*rand(1, NS));
            Sta.AR = zeros(NS, 1); % 할당된 RU
            i = ceil((PHY_header + Trigger_frame + SIFS) / U_slot);

            % 슬롯별 시뮬레이션 시작
            while i <= slot_num
                Sta.OBO = Sta.OBO - NR;
                flag_s = 0;
                flag_f = 0;
                Sta_ID_t = find(Sta.OBO <= 0);
                Sta.AR(Sta_ID_t) = ceil(NR*rand(length(Sta_ID_t), 1));
                
                for j = 1:NR
                    Sta_ID_RU = find(Sta.AR == j);
                    if isempty(Sta_ID_RU)
                        RR(j, 1) = RR(j, 1) + 1; % 유휴 count 증가
                    else
                        SR(Sta_ID_RU, 1) = SR(Sta_ID_RU, 1) + 1; % 접속 count 증가
                        if length(Sta_ID_RU) > 1  % 충돌 발생 시
                            SR(Sta_ID_RU, 3) = SR(Sta_ID_RU, 3) + 1; % 충돌 count 증가
                            RR(j, 3) = RR(j, 3) + 1;
                            flag_f = flag_f + 1; % 연속 충돌 count 증가
                            flag_s = 0; % 연속 성공 count 초기화
                            if flag_f >= 3 % 연속 3번 이상 충돌 시 OCW 2배 증가
                                Sta.OCW(Sta_ID_RU) = min(floor(2 * (Sta.OCW(Sta_ID_RU))), OCWmax);
                            elseif flag_f < 3 % 연속 3번 이하일 시 OCW 1.5배 증가
                                Sta.OCW(Sta_ID_RU) = min(floor(1.5 * (Sta.OCW(Sta_ID_RU))), OCWmax);
                            else
                                disp('error1'); % 예외 처리
                            end
                        elseif isscalar(Sta_ID_RU) % 전송 성공 시
                            SR(Sta_ID_RU, 2) = SR(Sta_ID_RU, 2) + 1; % 성공 count 증가
                            RR(j, 2) = RR(j, 2) + 1;
                            flag_s = flag_s + 1; % 연속 성공 count 증가
                            flag_f = 0; % 연속 실패 count 초기화
                            if flag_s >= 3
                                Sta.OCW(Sta_ID_RU) = max(floor(Sta.OCW(Sta_ID_RU) / 4), OCWmin);
                            elseif flag_s < 3
                                Sta.OCW(Sta_ID_RU) = max(floor(Sta.OCW(Sta_ID_RU) / 2), OCWmin);
                            else
                                disp('error2');
                            end
                        end
                    end
                end
                
                if ~isempty(Sta_ID_t)
                    Sta.OBO(Sta_ID_t) = floor(Sta.OCW(Sta_ID_t).*rand(1,length(Sta_ID_t)));
                    if NR == 1
                        DRR = (RU_tone(Sta.AR(Sta_ID_t))'.*BS.*CR*SS_num) / (SD+GI); % RU의 data rate
                    else
                        DRR = (RU_tone(Sta.AR(Sta_ID_t)).*BS.*CR*SS_num) / (SD+GI);
                    end
                    
                    i = i + max(ceil((PHY_header + (8 * MPDU_len(Sta_ID_t)./DRR)) / U_slot)) ...
                          + ceil((2*PHY_header + Back + Trigger_frame + 3*SIFS) / U_slot);
                    Sta.AR = zeros(NS, 1); % RU 할당 초기화
                else
                    i = i + 1;
                end
                
                NT = NT + 1;
            end
            
            % 결과 계산
            Idle_RU = mean(RR(:,1)'./sum(RR'));
            success_RU = mean(RR(:,2)'./sum(RR'));
            collision_RU = mean(RR(:,3)'./sum(RR'));
        
            access_Sta = mean(SR(:,1)'./(NT));
            success_Sta = mean(SR(:,2)./SR(:,1));
            collision_Sta = mean(SR(:,3)./SR(:,1));
    
            Th_Sta = SR(:,2).*(8 * MPDU_len')./(slot_num * U_slot)*10^-6; % (Mbps)
            Avg_Th = mean(Th_Sta); % (Mbps)
            Total_Th = sum(Th_Sta); % (Mbps)
            Fairness = (sum(Th_Sta)^2) / (NS*sum(Th_Sta.^2));
            efficiency = Total_Th / (DR*NR);
    
            Result_Set(k, NS, :) = [Idle_RU success_RU collision_RU access_Sta success_Sta collision_Sta Avg_Th Total_Th Fairness efficiency];
        end
        
        k = k + 1;
    end
    
    % 최종 결과 계산
    for i = Sta_num
        for j = 1:10
            final_result(m,i,j) = sum(Result_Set(:,i,j)) / (k-1);
        end
    end
    m = m + 1;
    end
    result = final_result;
end
