# FPGA Digital Clock & Stopwatch with UART Communication

## 1. Project Overview
본 프로젝트는 AMD Artix-7 기반의 Basys 3 FPGA 보드에서 동작하는 기존 디지털 시계 및 스톱워치 설계에 UART(Universal Asynchronous Receiver/Transmitter) 직렬 통신 모듈을 통합한 프로젝트입니다. 
PC와 FPGA 간의 양방향 통신 인터페이스를 구현하여, PC의 터미널(ASCII 입력)을 통해 시계/스톱워치를 제어하고, 보드에서 계산된 시간 데이터를 PC 화면으로 실시간 모니터링하는 것을 목적으로 합니다.

## 2. Development Environment
| Category | Details |
| :--- | :--- |
| Target Board | Basys 3 (AMD Artix-7 FPGA) |
| S/W Environment | Vivado 2022.2, VS Code |
| Language | Verilog HDL |
| Communication | UART (Baud rate: 9600 bps) |

## 3. Core Objectives & Upgrades
기존 Standalone 단일 보드 동작 시스템에서 다음과 같은 통신 및 제어 아키텍처가 확장되었습니다.
* UART Protocol Implementation: 외부 IP를 사용하지 않고 Baud Rate Generator, RX(수신), TX(송신) FSM을 Verilog로 직접 설계하여 직렬 통신 원리 파악.
* Multi-Master Control Resolution: 보드의 물리적 스위치/버튼 입력과 PC의 UART 수신 데이터를 동시에 안정적으로 처리하기 위한 중재 로직(`switch_register`) 구현.
* Data Decoding & Encoding: PC에서 입력되는 ASCII 코드를 하드웨어 제어 신호로 디코딩하고, 내부 24-bit 시간 데이터를 PC 출력용 포맷으로 인코딩하는 브릿지 설계.

## 4. System Architecture & Key Modules
최상위 모듈(`top_stopwatch_watch`)은 데이터패스와 제어부 외에 통신을 위한 핵심 하위 모듈들을 포함합니다.

* `uart_top.v` (UART Transceiver)
    * `baud_tick`: 시스템 클럭(100MHz)을 분주하여 타겟 통신 속도(9600 bps의 16배수 오버샘플링 등)에 맞는 Tick 생성.
    * `uart_rx` / `uart_tx`: Start bit, Data bits(8-bit), Stop bit로 구성된 프레임을 송수신하기 위한 상태 머신(IDLE, START, DATA, STOP) 구현.
* `data_register.v` (`switch_register`)
    * Control Arbitration: 보드의 로컬 스위치(`i_local_sw`) 입력과 UART를 통해 들어온 펄스(`i_uart_pulse`)의 상태 변화를 지속적으로 모니터링.
    * 펄스 토글(Toggle) 로직을 적용하여, PC와 보드 어느 쪽에서 제어 명령을 내리더라도 시스템이 충돌 없이 유연하게 상태(`o_control_sw`)를 갱신하도록 설계.
* `control_unit.v` (Upgraded FSM)
    * 기존 물리적 버튼에 직접 연결되던 제어 로직을 8-bit 제어 버스(`i_control_data`)를 수용하도록 리팩토링하여 확장성 확보.

## Block Diagram
* TOP
  <img width="2896" height="1375" alt="image" src="https://github.com/user-attachments/assets/9442da42-1866-425c-9cd9-369b90213d7c" />

## ASM
* UART_TX
  <img width="2700" height="1243" alt="image" src="https://github.com/user-attachments/assets/6c0aac13-3306-4ee5-9821-abe79f3ef1d6" />

* UART_RX
  <img width="2675" height="1220" alt="image" src="https://github.com/user-attachments/assets/caaafce2-9f1b-4d2c-ae2c-f457b7ad33cc" />

## 5. Key Features
* Two-Way Control: 
  * 보드 자체의 물리 스위치를 이용한 기존 제어 완벽 지원.
  * PC 터미널(Tera Term, Putty 등)에서 특정 ASCII 키보드 입력 시, 스톱워치 시작/정지/초기화 및 시계 모드 전환 제어 가능.
 
* Real-time Time Monitoring: 
  * 보드 내부에서 카운트되는 시간(시, 분, 초, 밀리초) 데이터를 지정된 프레임에 맞춰 PC 터미널로 지속 송신하여 화면에 출력.

## 6. Video
  https://github.com/user-attachments/assets/2fb138e0-c479-4422-aa46-3f6651dc5d23

## 7. Author
* 강동우 (Kang Dong-woo)


# ⏱️ UART 원격 제어 기능이 통합된 Basys3 기반 디지털 시계 및 스톱워치 시스템 (Verilog HDL)

본 프로젝트는 AMD Artix-7 FPGA (Basys3) 보드를 활용하여 실시간 디지털 시계(Watch) 및 스톱워치(Stopwatch) 기능을 구현하고, UART 직렬 통신 모듈을 추가하여 PC 환경에서 ASCII 명령어로 하드웨어를 제어하고 시간 데이터를 상호 전송할 수 있도록 확장한 통합 임베디드 시스템입니다.

---

## 1. 개발 환경 및 사양

* **하드웨어 대상**: Basys3 보드 (AMD Artix-7 FPGA)


* **사용 소프트웨어**: Vivado 2022.2, VS Code


* **사용 언어**: Verilog HDL


* **통신 사양**: UART 통신 (기본 보드레이트 파라미터: 153,600, 9600 Baudrate의 16배 오버샘플링 틱 스케일 구동)


* **입출력 인터페이스**:
* **입력 자원**: 시스템 클럭(100MHz), 리셋 버튼, 로컬 스위치 4개(`sw[3:0]`), 로컬 푸시 버튼 4개(`btn_r, btn_l, btn_u, btn_d`), UART RX 수신선


* **출력 자원**: FND 디지트 선택 신호(`fnd_digit[3:0]`), FND 세그먼트 데이터 신호(`fnd_data[7:0]`), UART TX 송신선


---

## 2. UART ASM
<img width="1381" height="1111" alt="UART_ASM_Tx" src="https://github.com/user-attachments/assets/ba5c4524-7c09-4ade-b26f-9195b758d72f" />
<img width="1461" height="901" alt="UART_ASM_Rx" src="https://github.com/user-attachments/assets/f510014b-ff6e-45ba-97cc-e98a1abbd623" />


---

## 3. 시스템 아키텍처 및 제어 신호 흐름

시스템은 로컬 하드웨어 입력(스위치 및 디바운스 처리된 버튼)과 UART 통신을 통해 수신된 원격 명령 플래그를 논리합(OR) 연산 및 레지스터 구조로 결합하여 최상위 FSM 제어부로 인입시키는 구조를 취하고 있습니다.
<img width="3511" height="1681" alt="top_watch_uart" src="https://github.com/user-attachments/assets/28ed78f9-26c3-4533-9e5a-a1e22341486d" />

```
top_stopwatch_watch (최상위 제어 모듈)
├── uart_top : UART 통신 코어 (RX/TX 인프라 및 보드레이트 생성기)
│   ├── uart_rx : 직렬 데이터를 8비트 병렬 데이터로 복원 및 수신 완료(rx_done) 플래그 생성
│   ├── uart_tx : 병렬 데이터를 프레임 규격에 맞춰 직렬 송신
│   └── baud_tick : $100\text{MHz} / 153,600 = 651$ 카운터 분주 기반 오버샘플링 틱 제공
├── ascii_decoder : 수신된 문자 데이터를 시스템 제어용 펄스 플래그로 매핑
├── switch_register : 단발성 UART 펄스를 상상태가 보존되는 레벨 신호로 변환 및 로컬 스위치 동기화
├── ascii_sender : 원격 시간 읽기 요청 시 24비트 시간 데이터를 패킷화하여 TX 송신부로 전송 제어
├── btn_debounce (X4) : 기계식 버튼 입력을 100kHz 샘플링을 통해 채터링 소거 후 단일 펄스화
├── control_unit : 제어 버스(`w_control_data`)를 참조하여 시스템 상태 전이(FSM) 수행
├── watch_datapath & stopwatch_datapath : 시계 계시 및 스톱워치 데이터 연산 처리부
└── fnd_controller : 동적 스캔 구동 기법 및 설정 모드 디지트 깜빡임 제어

```

---

## 4. 원격 통신 명령어 및 인터페이스 사양

### 4.1. UART 제어 명령어 ASCII 매핑 리스트

`ascii_decoder` 모듈을 통해 PC 터미널에서 입력된 특정 문자는 하드웨어 제어 버스 레벨의 내부 신호로 실시간 동기화됩니다.

* **`'r'` (0x72)**: 스톱워치 Run/Stop 트리거 또는 시계 설정 커서 우측 이동 (`btn_r`과 매핑)


* **`'l'` (0x6C)**: 스톱워치 Clear 트리거 또는 시계 설정 커서 좌측 이동 (`btn_l`과 매핑)


* **`'u'` (0x75)**: 시계 설정 모드에서 선택된 시간 값 1 증가 (`btn_u`와 매핑)


* **`'d'` (0x64)**: 시계 설정 모드에서 선택된 시간 값 1 감소 (`btn_d`와 매핑)


* **`'0'` (0x30)**: 카운트 방향 전환 제어 스위치 토글 플래그


* **`'1'` (0x31)**: 디지털 시계 / 스톱워치 디스플레이 전환 스위치 토글 플래그


* **`'2'` (0x32)**: 시계 화면 형식 전환 (초:밀리초 $\leftrightarrow$ 시:분) 스위치 토글 플래그


* **`'3'` (0x33)**: 디지털 시계 설정 모드 진입/탈출 스위치 토글 플래그



### 4.2. 혼합 제어 로직 구조 (`w_control_data`)

물리 버튼 신호와 원격 문자 디코딩 플래그는 비트 와이즈 논리합(OR) 연산 처리를 거쳐 통합 제어 신호선 집합인 `w_control_data`를 구성하며, `control_unit`에 다이렉트로 인입되어 상호 동일한 우선순위 수준의 실시간 제어 성능을 보장합니다.

---

## 5. 핵심 모듈 설계 세부 사양

### 5.1. 비동기 신호 처리부 (`switch_register.v`)

* **설계 목적**: 물리적 토글 스위치는 특정 전압 레벨을 영구 유지하는 반면, UART 데이터 수신 신호는 문자 처리 시점에만 일시적으로 인서트되는 펄스 속성을 가집니다.


* **동작 매커니즘**: `i_local_sw` 변경을 항시 감시하여 물리 스위치의 변동이 발생하면 우선적으로 제어 출력을 업데이트하고, 로컬 스위치에 변동이 없는 평상시 상태에서 `i_uart_pulse` 비트 패튼이 감지되면 해당 비트 출력을 반전(`~o_control_sw`)시키는 구조를 설계함으로써 원격 펄스 입력을 통해 가상의 가역성 스위치 하드웨어를 완벽하게 모사했습니다.



### 5.2. 원격 데이터 전송 제어부 (`ascii_sender.v`)

* **설계 목적**: PC 사이드에서 시간 확인 요청 플래그(`read_time`) 신호가 전달되었을 때, 다중 비트 시간 정보 패킷을 유실 없이 직렬화 파이프라인으로 안전하게 바이패스하기 위함입니다.


* **상태 머신 구동**: `IDLE`, `SEND`, `WAIT` 3가지 제어 버퍼 상태로 설계되어 하드웨어 송신기가 점유 중(`tx_busy == 1`)인 시점을 완벽하게 회피하며 시계 멀티플렉서 데이터(`w_mux`)를 데이터 버스에 인가합니다.



---

## 6. 시뮬레이션 및 하드웨어 테스트 결과

### 6.1. UART 제어 기반 스톱워치 계시 검증

* 테스트벤치 상에서 타스크 스케줄러(`UART_SENDER`)를 활용해 원격으로 문자 `"1"`을 인입시켜 스톱워치 모드로 하드웨어를 절체했습니다.


* 이후 문자 `"r"` 커맨드를 직렬 라인으로 주입했을 때 수신 회로의 프레임 연산(`c_state` 전이 및 `bit_cnt_reg` 카운팅)을 거쳐 최종적으로 `rx_done` 신호 플래그와 함께 `control_unit` 내에서 `RUN` 상태 기어가 부드럽게 인게이지되는 과정을 시뮬레이션으로 확인했습니다.

<img width="2941" height="1278" alt="image" src="https://github.com/user-attachments/assets/5cfb17c3-9395-43fa-b653-4a7e3c0b5184" />
<img width="2907" height="1283" alt="image" src="https://github.com/user-attachments/assets/bfce306f-135a-437c-a7a1-67afe1b29ffb" />
<img width="2850" height="1236" alt="image" src="https://github.com/user-attachments/assets/7d6439f3-d161-48d1-baaf-7b92598ba6d1" />


### 6.2. 원격 커맨드를 이용한 시계 시간 보정 시뮬레이션 검증

* 시계 보정 모드 진입 후 문자 `"u"` 패킷을 연속으로 투하했을 때 내부 `watch_datapath` 상의 시간 레지스터 값이 초기값 12시에서 13시, 14시로 계단식 증폭하는 연산 안정성을 획득했습니다.


* 이어서 화면 이동 명령어 `"r"` 처리 후 감소 키워드 `"d"`를 인가했을 때 내부 분 단위 유닛 계수기가 다운 카운팅 경계 조건에 연동되어 14시 59분, 14시 58분 영역으로 에러 없이 디크리먼트 처리가 수행됨을 타이밍 파형 상에서 완전 검증했습니다.

<img width="2875" height="1244" alt="image" src="https://github.com/user-attachments/assets/eaf0be1c-8d20-4bfc-acb5-55052c5fc325" />


---

## 7. 트러블슈팅 및 배운 점

### 7.1. 비동기 디코더 데이터 연속 반전 결함 해결

* **문제 상황**: UART 수신 완료 플래그 조건에 맞춰 제어 유닛 상태 처리가 이루어질 때, 특정 상태 구간(DATA $\rightarrow$ STOP)에서 하드웨어 제어 출력 플래그가 클럭 동기화 타이밍 문제로 인해 제어 상태를 안정적으로 고수하지 못하고 계속하여 원치 않는 상태 반전(Toggling) 에러 유발.


* **원인 분석**: 기존 디코더 하드웨어 기술 단계에서 시스템 메인 `clk` 도메인 트리거 구조와 물리적 프레임 패킷 수신 완결 플래그인 `rx_done` 펄스 라인의 교차 무결성 검증 조건이 명확하게 정립되지 않아, 수신 사이클이 지속되는 주기 동안 의도치 않은 무조건적인 상태 머신 전이 분기가 상시 오픈되어 있었음.


* **해결 방안**: ASCII 디코더 모듈 내부에 메인 시스템 클럭 동기화 공정을 설계하여 반드시 `rx_done` 유효 활성 상태일 때에만 동기식 구조로 케이스 분기 트랜잭션이 활성화되도록 구조를 완전 수정하고, 레벨 유지가 요구되는 스위치 성격의 데이터는 전용 격리 하드웨어 모듈인 `switch_register`를 신규 설계 및 삽입하여 버그를 완벽히 억제했습니다.
