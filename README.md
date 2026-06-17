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
