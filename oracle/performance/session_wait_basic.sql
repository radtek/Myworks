SELECT SID, SERIAL#, 
       USERNAME, STATUS,
       OSUSER, MACHINE, PROGRAM, 
       PROCESS, SQL_ID,
       LOCKWAIT, -- V$LOCK의 KADDR 값과 동일
       P1,     -- Parameter1의 값
       P1TEXT, -- Parameter1에 대한 설명 (V$EVENT_NAME 뷰 PARAMETER1 값과 동일)
       P2,     -- Parameter2의 값
       P2TEXT, -- Parameter2에 대한 설명 (V$EVENT_NAME 뷰 PARAMETER2 값과 동일)
       P3,     -- Parameter3의 값
       P3TEXT, -- Parameter3에 대한 설명 (V$EVENT_NAME 뷰 PARAMETER3 값과 동일)
       EVENT,      -- 대기 이벤트 이름 (V$EVENT_NAME 뷰 NAME 값과 동일)
       WAIT_CLASS, -- 대기 클래스 이름 : USER I/O, SYSTEM I/O, Application, Commit 등등
       TIME_SINCE_LAST_WAIT_MICRO, -- WAIT_TIME에서 11g 이후 대체 micro second (1/10^6)
                                   --(STATE가 WATING이 아닐때만 의미가 있음 : 가장 최근 대기가 끝난 후 경과시간)
       STATE, -- WAITING : 실제 대기중 WAIT_TIME_MICRO 값으로 실제 대기시간 확인가능. 
              -- WAITED SHORT TIME : 1/100초 이하의 대기 후 CPU 점유하며 작업중 WAIT_TIME_MICRO 값을 -1로 표시되는것으로 확인도 가능.
              -- WAITED KNOWN TIME : 1/100초 이상의 대기 후 CPU 점유하며 작업중 WAIT_TIME_MICRO 값으로 실제 대기시간 확인가능.
       WAIT_TIME_MICRO -- SECONDS_IN_WAIT에서 11g 이후 대체 micro second (1/10^6)
                       -- STATE가 WAITING 일때 실제대기시간, 아닐때는 가장 최근 대기한 작업의 시간이 남아있음
FROM V$SESSION
--WHERE USERNAME = 'WATCHER';

-- V$SESSION_WAIT로 제한적인 대기 시간만 확인가능
-- V$SESSION_EVENT로 제한적인 EVENT당 누적대기시간 확인가능
