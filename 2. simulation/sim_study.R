# ==============================================================================
# File: 2. simulation/sim_study.R
# Description: Monte Carlo Simulation validating the CLI Test
# ==============================================================================

# 0. 환경 설정
if (!requireNamespace("MASS", quietly = TRUE)) install.packages("MASS")
library(MASS)

# [중요] 핵심 함수 불러오기
# RStudio 프로젝트 Root에서 실행한다고 가정
source("R/functions.R") 

set.seed(2026)

# 1. 데이터 생성 함수 (Data Generation Process)
generate_sim_data <- function(N, lambda, impact, rho) {
  U <- rnorm(N, 0, 1) # Latent Confounder
  
  # 처치변수 G (선택 편향 존재)
  prob_g <- plogis(0.5 * U)
  G <- rbinom(N, 1, prob_g)
  
  # 오차항 생성 (Rho > 0 이면 가정 위배)
  Sigma_err <- matrix(c(1, rho, rho, 1), nrow=2)
  errors_pc1 <- MASS::mvrnorm(N, mu=c(0,0), Sigma=Sigma_err)
  
  e_P  <- errors_pc1[,1]; e_C1 <- errors_pc1[,2]
  e_Y  <- rnorm(N);       e_C2 <- rnorm(N)
  
  # 관측변수 생성
  P  <- lambda * U + e_P
  C1 <- lambda * U + e_C1
  Y  <- lambda * U + impact * G + e_Y 
  C2 <- lambda * U + e_C2
  
  return(data.frame(G=G, P=P, Y=Y, C1=C1, C2=C2))
}

# 2. 시뮬레이션 조건 설정
conditions <- expand.grid(
  Sample_Size = c(500, 1000, 2000),      
  Loading = c(0.3, 0.5, 0.8),           
  Impact = c(0, 0.5, 1),              
  Violation_Rho = c(0, 0.2, 0.4)   # 0=Type I Error, >0=Power
)

REPLICATIONS <- 1000
ADJUST_METHOD <- "bonferroni"

# 3. 시뮬레이션 실행
final_results <- data.frame()

cat("=== Simulation Start ===\n")

for(i in 1:nrow(conditions)) {
  cond <- conditions[i,]
  reject_count <- 0
  
  for(r in 1:REPLICATIONS) {
    sim_data <- generate_sim_data(cond$Sample_Size, cond$Loading, cond$Impact, cond$Violation_Rho)
    
    # CLI Test 실행
    res <- test_tetrad_assumption(sim_data, "Y", "P", "C1", "C2", "G", adjust_method=ADJUST_METHOD)
    
    if (res$decision$reject) reject_count <- reject_count + 1
  }
  
  rate <- reject_count / REPLICATIONS
  final_results <- rbind(final_results, cbind(cond, Rejection_Rate = rate))
  
  if(i %% 5 == 0) cat(sprintf("[%d/%d] Done. Rho=%.1f -> Rate=%.3f\n", i, nrow(conditions), cond$Violation_Rho, rate))
}

# 4. 결과 출력
cat("\n=== [Type I Error Check (Rho=0)] Target ~ 0.05 ===\n")
print(subset(final_results, Violation_Rho == 0))

cat("\n=== [Power Analysis (Rho>0)] Target -> 1.00 ===\n")
print(subset(final_results, Violation_Rho > 0))