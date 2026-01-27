# CLI-Compass-Continuous: 공통추세 가정 위배 시 보정된 이중차분법(aDID)의 타당성 검증

이 저장소는 탐지변수(Compass Variable)를 활용한 조정된 DID(Adjusted DID) 분석과 그 핵심 가정인 '조건부 지역 독립성'을 검증하는 통계적 절차를 구현한 R 코드를 포함하고 있습니다.

**연구 요약:**
이중차분법(DID)은 공통추세 가정이 위반될 경우 편향된 추정치를 산출할 위험이 있습니다. 이를 보완하기 위해 탐지변수를 활용한 aDID가 제안되었으나, 그 타당성을 검증하는 경험적 절차는 미비했습니다.
본 연구는 탐지변수의 조건부 지역 독립성(Conditional Local Independence)을 검증하는 Tetrad Test 절차를 제안하고, 몬테카를로 시뮬레이션을 통해 검정력을 확인하였습니다. 
또한, 경기교육종단연구 자료를 이용한 실증 분석을 통해 식별 가정 검증의 중요성을 입증하였습니다.

## 📂 저장소 구조 (Repository Structure)

이 프로젝트는 크게 **핵심 함수**, **시뮬레이션 검증**, **실증 분석 예시**로 구성되어 있습니다.

```bash
Metric-Compass/
├── R/
│   └── functions.R         # [핵심] Tetrad Test 및 aDID 추정 함수 정의
├── simulation/
│   └── sim_study.R         # 몬테카를로 시뮬레이션 (제1종 오류 및 검정력 검증)
└── analysis/
    └── case_study.R        # 경기교육종단연구 데이터를 활용한 분석 예시 및 비교


