# ==============================================================================
# File: 3. illustration/illustration_study.R
# Description: Empirical Illustration
# ==============================================================================

library(dplyr)
library(haven)
source("1. functions/functions.R") # 함수 로드

# ------------------------------------------------------------------------------
# 1. 데이터 로드 및 전처리 (GEPS 실제 데이터)
# ------------------------------------------------------------------------------
# [분석 환경에 맞춰 파일 경로를 수정하세요]

# 1-1. 데이터 불러오기
# x1: 5차년도 학교, x2: 6차년도 학교, x3: 5차년도 학생, x4: 6차년도 학생
# (논문 데이터 기준: 중2 시점 5차년도, 중3 시점 6차년도)
x1 <- read_sav("Y5_SCH.sav") 
x2 <- read_sav("Y6_SCH.sav") 
x3 <- read_sav("Y5_STU.sav") 
x4 <- read_sav("Y6_STU.sav") 

# 1-2. 데이터 병합 (Student ID 및 School ID 기준)
x_merged <- x3 %>%
 inner_join(x4, by = "STUID") %>%
 inner_join(x1, by = "Y5M_SCHID") %>%
 inner_join(x2, by = "Y6M_SCHID")

# 1-3. 분석 변수 추출 및 조건화
# - Y5M_SCH4_10 == 2: 사전 시점에 정책(진로집중과정) 미시행 학교 한정
x10 <- x_merged %>%
 select(
   Y6_Target = Y6M_SCH4_10, # 사후 정책 시행 여부
   Y5_Target = Y5M_SCH4_10, # 사전 정책 시행 여부
   KOR_Post  = Y6E_KOR_VS,  # 사후 국어 점수
   KOR_Pre   = Y5M_KOR_VS,  # 사전 국어 점수
   MATH_Post = Y6E_MATH_VS, # 탐지변수 1 (수학 점수)
   ENG_Post  = Y6E_ENG_VS   # 탐지변수 2 (영어 점수)
 ) %>%
 filter(Y5_Target == 2)

# 1-4. 최종 분석 데이터셋(x11) 구성
x11 <- data.frame(
 A  = as.numeric(gsub(2, 0, x10$Y6_Target)), # 2(미시행)를 0으로 변환
 P  = as.numeric(x10$KOR_Pre),
 Y  = as.numeric(x10$KOR_Post),
 C1 = as.numeric(x10$MATH_Post),
 C2 = as.numeric(x10$ENG_Post)
) %>% na.omit()

# ------------------------------------------------------------------------------
# 2. 기본 분석 (Baseline Models)
# ------------------------------------------------------------------------------
cat("\n--- [1] ANCOVA Model ---\n")
print(summary(lm(Y ~ A + P, data = x11)))

cat("\n--- [2] Gain Score Model ---\n")
print(summary(lm(I(Y - P) ~ A, data = x11)))

# ------------------------------------------------------------------------------
# 3. aDID 분석 (Adjusted DID)
# ------------------------------------------------------------------------------
cat("\n--- [3] aDID Analysis (Using Control C1) ---\n")
adjusted_did_analytic(G = "A", Y = "Y", P = "P", C = "C1", x11)

cat("\n--- [3] aDID Analysis (Using Control C2) ---\n")
adjusted_did_analytic(G = "A", Y = "Y", P = "P", C = "C2", x11)

# ------------------------------------------------------------------------------
# 4. 탐지변수 가정 검정 (CLI Test)
# ------------------------------------------------------------------------------
cat("\n--- [4] CLI Assumption Test ---\n")
# 탐지변수(C1, C2)가 유효한지 검증
result <- test_tetrad_assumption(
  data = x11,
  outcome = "Y", pre = "P", detect1 = "C1", detect2 = "C2", group = "A"
)

print(result)