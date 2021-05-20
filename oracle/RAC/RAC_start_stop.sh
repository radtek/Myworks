1. rac 시작/종료
   - 전체 : crsctl stop has
   - 시작 : crsctl start crs
   - 종료 : crsctl stop crs
   - 체크 : crsctl check crs
   - 상태 : crsctl stat res -t
             crs_stat -t
             crs_stat -p

   - ocr : ocrcheck
            crsctl query css votedisk

2. rac db 관련 명령어 
   - 인스턴스
     시작 : srvctl start instance -d 인스턴스명  -n node명 
     종료 : srvctl stop instance -d 인스턴스명  -n node명 
     상태 : srvctl status instance -d 인스턴스명  -n node명 

   - 리스너
     시작 : srvctl start  listener -n 노드명
     종료 : srvctl stop listener -n 노드명
     상태 : srvctl status listener -n 노드명
