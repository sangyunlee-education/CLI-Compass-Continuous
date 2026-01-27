# CLI-Compass-Continuous: 공통추세 가정 위배 시 보정된 이중차분법(aDID)의 타당성 검증

이 저장소(Repository)는 **탐지변수(Compass Variable)를 활용한 교정된 DID(Adjusted DID) 분석**과 그 핵심 가정인 **'조건부 지역 독립성'을 검증하는 통계적 절차(Tetrad Test)**를 구현한 R 코드를 포함하고 있습니다.

## 📌 연구 배경 및 목적 (Abstract)
이중차분법(Difference-in-Differences, DID)은 정책의 효과를 추정하는 유용한 접근법이지만, **공통추세 가정(common trend assumption)**이 위반될 경우 추정치가 편향될 수 있습니다. 이를 보완하기 위해 탐지변수(compass variable)를 활용한 **교정된 DID(adjusted DID)** 접근법이 제안되었으나, 탐지변수의 필수 조건인 ‘조건부 지역 독립성’을 경험적으로 검증하는 절차는 미비했습니다.

본 연구는 다음과 같은 기여를 목적으로 합니다:
1.  **통계적 검정 절차 제시:** 탐지변수의 조건부 지역 독립성을 검증할 수 있는 **Tetrad Test** 절차를 제안합니다.
2.  **시뮬레이션 검증:** 몬테카를로 시뮬레이션(Monte Carlo Simulation)을 통해 제안된 절차가 제1종 오류를 안정적으로 제어하고, 가정 위배를 포착하는 충분한 검정력을 갖추었음을 확인하였습니다.
3.  **실증 분석 예시:** 경기교육종단연구 자료를 활용하여 기존 분석(ANCOVA, DID)과 제안된 방법(aDID)의 결과를 비교하고, 식별 가정 검증의 중요성을 입증합니다.

## 📂 저장소 구조 (Repository Structure)

```bash
CLI-Compass-Continuous/
├── R/
│   └── functions.R         # [핵심] Tetrad Test 및 aDID 추정 함수 정의 (Base R)
├── simulation/
│   └── sim_study.R         # 몬테카를로 시뮬레이션 (제1종 오류율 및 검정력 검증)
└── analysis/
    └── case_study.R        # 경기교육종단연구 데이터를 활용한 실증 분석 예시
```
