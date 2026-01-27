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

✨ 주요 기능 (Key Features)

1. 탐지변수 가정 검정 (Tetrad Test)탐지변수(예: 수학, 영어 점수)가 결과변수(예: 국어 점수)의 잠재적 교란 요인을 적절히 반영하고 있는지 통계적으로 검정합니다.특징: lavaan 등 무거운 패키지 의존성 없이 Base R로 구현되어 가볍고 빠릅니다.보정: 다중 비교 문제 해결을 위한 P값 보정(Bonferroni, Holm 등)을 지원합니다.

2. 교정된 이중차분법 (Adjusted DID Estimation)
공통추세 가정이 위배되는 상황에서, 검증된 탐지변수를 활용하여 편향을 제거한 처치 효과를 추정합니다.

🚀 사용 방법 (Usage)

1. 환경 설정 및 함수 로드

# 필수 패키지 설치 (데이터 핸들링 및 시뮬레이션용)
if (!require("MASS")) install.packages("MASS")
if (!require("dplyr")) install.packages("dplyr")

# 핵심 함수 로드
source("R/functions.R")

# 핵심 함수 로드
source("R/functions.R")


2. 탐지변수 가정 검정 (Tetrad Test)
사전점수(P), 사후점수(Y), 그리고 두 개의 탐지변수(C1, C2) 간의 관계를 검정합니다.

# 데이터와 변수명을 지정하여 실행
result <- test_tetrad_assumption(
  data = my_data,
  outcome = "Y_post",   # 사후 점수 (예: 국어)
  pre = "Y_pre",        # 사전 점수
  detect1 = "C_math",   # 탐지변수 1 (예: 수학)
  detect2 = "C_eng",    # 탐지변수 2 (예: 영어)
  group = "Treatment"   # 처치 집단 변수 (0/1)
)

print(result)

판정: 결과가 "ACCEPT H0"라면 해당 탐지변수들을 사용하여 aDID 분석을 수행할 수 있습니다.

3. aDID 분석 수행
adjusted_did_analytic(
  G = "Treatment", 
  Y = "Y_post", 
  P = "Y_pre", 
  C = "C_math",   # 검증된 탐지변수 사용
  data = my_data
)

📦 요구 사항 (Requirements)
R version: 4.0.0 이상
Dependencies: MASS (시뮬레이션용), dplyr, haven (데이터 처리용)
Encoding: UTF-8
