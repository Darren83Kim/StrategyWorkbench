# Friend Invite Event Sequence Diagram

초대 이벤트의 전체 흐름을 Mermaid 시퀀스 다이어그램으로 정리한 문서입니다.

```mermaid
sequenceDiagram
    autonumber

    participant A as A Client (초대자)
    participant B as B Client (피초대자)
    participant S as Server
    participant H as Hive SDK / Server

    rect rgb(240, 248, 255)
    Note over A, H: 1. 초대하는 유저 A - 팝업 진입
    A->>S: WebRequestInviteEventInfo
    S->>H: /ua/process (조회)
    S-->>A: WebResponseInviteEventInfo<br/>(EventId, RewardList, 진행도 등 표시)
    end

    rect rgb(255, 250, 240)
    Note over A, H: 2. 초대하는 유저 A - 링크 공유
    A->>H: getAppInvitationData()<br/>showUAShare(...)
    Note right of A: 클라 ↔ Hive SDK<br/>(서버 패킷 없음)
    end

    rect rgb(240, 255, 240)
    Note over B, H: 3. 초대받는 유저 B - sender 확보
    B->>H: setEngagementReady(true)<br/>getAppInvitationSenderInfo()
    H-->>B: sender_vid 획득 반환
    Note right of B: 클라 ↔ Hive SDK<br/>(서버 패킷 없음)
    end

    rect rgb(255, 240, 245)
    Note over B, H: 4. 초대받는 유저 B - 서버 등록
    B->>S: WebRequestInviteEventRegister(SenderVid)
    Note right of S: 신규/자신/중복 검증
    S->>H: /ua/getSenderVid (재검증)
    S-->>B: WebResponseInviteEventRegister(IsRegistered)
    Note right of S: 초대 관계가 서버에 저장됨
    end

    rect rgb(253, 245, 230)
    Note over B, H: 5. 초대받는 유저 B - 미션 행동 발생
    B->>S: 기존 게임 행동 패킷 (미션/결제 등)
    Note right of S: 내부적으로 sender_vid > 0 확인
    S->>H: /api/cpa 호출
    end

    rect rgb(240, 248, 255)
    Note over A, H: 6. 초대하는 유저 A - 진행도 재조회
    A->>S: WebRequestInviteEventInfo
    S->>H: /ua/process (로컬 수령 상태 조회)
    S-->>A: WebResponseInviteEventInfo<br/>(초대 수, 미션 카운트 증가 반영)
    end

    rect rgb(245, 245, 255)
    Note over A, H: 7. 초대하는 유저 A - 보상 수령
    A->>S: WebRequestInviteEventGetReward<br/>(EventId, RewardType, TargetList)
    Note right of S: Hive 진행도/로컬 수령 상태 확인<br/>보상 지급 및 DB 저장
    S-->>A: WebResponseInviteEventGetReward<br/>(FriendInviteEventInfo, RewardList)
    end
```

## Step Summary

1. 초대자 A가 이벤트 팝업에 진입하면 서버가 Hive 조회 결과를 포함한 이벤트 정보를 반환합니다.
2. 초대자 A는 Hive SDK를 통해 초대 링크를 생성하고 공유합니다.
3. 피초대자 B는 Hive SDK에서 `sender_vid`를 확보합니다.
4. 피초대자 B는 `SenderVid`를 서버에 등록하고, 서버는 Hive를 통해 재검증 후 초대 관계를 저장합니다.
5. 피초대자 B의 미션 행동이 발생하면 서버가 내부 검증 후 Hive `CPA`를 호출합니다.
6. 초대자 A가 진행도를 재조회하면 누적 초대 수와 미션 카운트가 반영된 결과를 받습니다.
7. 초대자 A가 보상 수령을 요청하면 서버가 진행도와 수령 상태를 확인한 뒤 보상을 지급합니다.
