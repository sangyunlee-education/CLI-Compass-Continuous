# ==============================================================================
# File: 1. functions/functions.R
# Description: Core functions for CLI Test and Adjusted DID (aDID)
# Author: Sangyun Lee
# ==============================================================================

#' 탐지변수의 조건부 지역 독립성 검정 (CLI Test)
#'
#' @param data 분석할 데이터프레임
#' @param outcome 사후점수 변수명 (String) e.g., "Y"
#' @param pre 사전점수 변수명 (String) e.g., "P"
#' @param detect1 첫 번째 탐지변수명 (String) e.g., "C1"
#' @param detect2 두 번째 탐지변수명 (String) e.g., "C2"
#' @param group 처치 집단 변수명 (String) e.g., "G"
#' @param alpha 유의수준 (기본값 0.05)
#' @param adjust_method P값 보정 방법 (기본값 "bonferroni")
#'
#' @return tetrad_test 클래스 객체
#' @export
test_tetrad_assumption <- function(data, outcome, pre, detect1, detect2, group, 
                                   alpha = 0.05, adjust_method = "bonferroni") {
  
  # 1. 필수 변수 및 데이터 타입 확인
  vars_needed <- c(outcome, pre, detect1, detect2, group)
  if (!all(vars_needed %in% names(data))) {
    missing <- vars_needed[!vars_needed %in% names(data)]
    stop("Error: 데이터에 다음 변수가 없습니다: ", paste(missing, collapse=", "))
  }
  
  numeric_vars <- c(outcome, pre, detect1, detect2)
  if (!all(sapply(data[numeric_vars], is.numeric))) {
    stop("Error: 결과변수와 탐지변수는 모두 수치형(numeric)이어야 합니다.")
  }
  
  # 2. 그룹별 CLI 검정 수행
  groups <- sort(unique(data[[group]]))
  result_table <- data.frame()
  
  for (g in groups) {
    # Listwise Deletion
    sub_data <- na.omit(data[data[[group]] == g, numeric_vars])
    N <- nrow(sub_data)
    
    # 샘플 수 부족 예외 처리
    if (N < 5) {
      result_table <- rbind(result_table, 
                            data.frame(Group=g, Estimate=NA, SE=NA, Z_value=NA, Raw_P=NA))
      next
    }
    
    # 공분산 행렬 계산
    S <- cov(sub_data)
    idx_P  <- which(colnames(S) == pre)
    idx_Y  <- which(colnames(S) == outcome)
    idx_C1 <- which(colnames(S) == detect1)
    idx_C2 <- which(colnames(S) == detect2)
    
    # Tetrad (tau) 계산
    s_pc1 <- S[idx_P, idx_C1]; s_yc2 <- S[idx_Y, idx_C2]
    s_pc2 <- S[idx_P, idx_C2]; s_yc1 <- S[idx_Y, idx_C1]
    tau_est <- s_pc1 * s_yc2 - s_pc2 * s_yc1
    
    # Delta Method (Standard Error)
    gradient <- c(s_yc2, s_pc1, -s_yc1, -s_pc2)
    pairs_idx <- list(c(idx_P, idx_C1), c(idx_Y, idx_C2), c(idx_P, idx_C2), c(idx_Y, idx_C1))
    
    cov_of_covs <- matrix(0, 4, 4)
    for (i in 1:4) {
      for (j in 1:4) {
        a <- pairs_idx[[i]][1]; b <- pairs_idx[[i]][2]
        c <- pairs_idx[[j]][1]; d <- pairs_idx[[j]][2]
        cov_of_covs[i,j] <- (S[a,c]*S[b,d] + S[a,d]*S[b,c]) / (N - 1)
      }
    }
    
    var_tau <- t(gradient) %*% cov_of_covs %*% gradient
    se_tau <- sqrt(as.numeric(var_tau))
    
    # Z-test
    if (is.na(se_tau) || se_tau == 0) {
      z_val <- NA; p_val <- NA
    } else {
      z_val <- tau_est / se_tau
      p_val <- 2 * (1 - pnorm(abs(z_val)))
    }
    
    result_table <- rbind(result_table, 
                          data.frame(Group=g, Estimate=tau_est, SE=se_tau, Z_value=z_val, Raw_P=p_val))
  }
  
  # 3. P값 보정 및 최종 판정
  valid_p_idx <- !is.na(result_table$Raw_P)
  result_table$Adj_P <- NA
  if (any(valid_p_idx)) {
    result_table$Adj_P[valid_p_idx] <- p.adjust(result_table$Raw_P[valid_p_idx], method = adjust_method)
    min_p <- min(result_table$Adj_P[valid_p_idx])
    reject_h0 <- (min_p < alpha)
  } else {
    reject_h0 <- FALSE
  }
  
  output <- list(
    input_info = list(outcome=outcome, pre=pre, detect=c(detect1, detect2), 
                      group=group, alpha=alpha, adjust=adjust_method),
    result_table = result_table,
    decision = list(reject = reject_h0, min_p = min(result_table$Adj_P, na.rm=TRUE))
  )
  
  class(output) <- "tetrad_test"
  return(output)
}

#' @export
print.tetrad_test <- function(x, digits = 4, ...) {
  cat("\n=== Tetrad Test of Conditional Independence ===\n")
  cat("-----------------------------------------------\n")
  cat("Adjustment Method :", x$input_info$adjust, "\n")
  cat("Significance Level:", x$input_info$alpha, "\n\n")
  
  res_print <- x$result_table
  numeric_cols <- c("Estimate", "SE", "Z_value", "Raw_P", "Adj_P")
  res_print[numeric_cols] <- round(res_print[numeric_cols], digits)
  
  print(res_print, row.names = FALSE)
  
  cat("\n-----------------------------------------------\n")
  decision_txt <- ifelse(x$decision$reject, 
                         "Result: REJECT H0 (Assumption Violated)", 
                         "Result: ACCEPT H0 (Assumption Holds)")
  cat(decision_txt, "\n")
  cat("-----------------------------------------------\n")
}

#' Adjusted Difference-in-Differences (aDID) Analytic Method
#'
#' @param G 처리그룹 지시자 (변수명 String)
#' @param Y 결과 변수명 (String)
#' @param P 정책/처리 강도 변수명 (String)
#' @param C 통제 변수명 (String)
#' @param data 데이터프레임
#' @param conf_level 신뢰수준 (기본 0.95)
#'
#' @return aDID 추정 결과 리스트
#' @export
adjusted_did_analytic <- function(G, Y, P, C, data, conf_level = 0.95) {
  
  n <- nrow(data)
  
  # 1. G 변수 처리 (Binary 확인)
  if (! (is.numeric(data[[G]]) && all(data[[G]] %in% c(0, 1))) ) {
    data[[G]] <- as.factor(data[[G]])
    lev <- levels(data[[G]])
    if (length(lev) != 2) stop("G 변수는 반드시 이진(0/1)이어야 합니다.")
    data[[G]] <- as.integer(data[[G]] == lev[2])
  }
  
  # 2. OLS 회귀분석 수행
  fP <- lm(stats::as.formula(paste(P, "~", C, "+", G)), data = data, x = TRUE)
  fY <- lm(stats::as.formula(paste(Y, "~", C, "+", G)), data = data, x = TRUE)
  
  b1 <- coef(fP)[C]; g1 <- coef(fP)[G]
  b2 <- coef(fY)[C]; g2 <- coef(fY)[G]
  
  if (abs(b1) < .Machine$double.eps) stop("P 회귀의 C 계수가 0에 근접하여 delta 계산 불가.")
  
  delta <- b2 / b1
  tau   <- g2 - delta * g1
  
  # 3. 분산 및 표준오차 계산 (Delta Method)
  X <- model.matrix(fY)
  XtXinv <- solve(crossprod(X))
  k <- ncol(X)
  
  eP <- resid(fP); eY <- resid(fY)
  sigma_pp <- sum(eP^2) / (n - k)
  sigma_yy <- sum(eY^2) / (n - k)
  sigma_py <- sum(eP * eY) / (n - k)
  
  idxC <- which(colnames(X) == C)
  idxG <- which(colnames(X) == G)
  
  invCC <- XtXinv[idxC, idxC]; invGG <- XtXinv[idxG, idxG]; invCG <- XtXinv[idxC, idxG]
  
  # 공분산 행렬 V 구성
  V <- matrix(0, 4, 4)
  V[1,1] <- sigma_pp * invCC; V[2,2] <- sigma_yy * invCC
  V[3,3] <- sigma_pp * invGG; V[4,4] <- sigma_yy * invGG
  V[1,2] <- V[2,1] <- sigma_py * invCC
  V[3,4] <- V[4,3] <- sigma_py * invGG
  V[1,3] <- V[3,1] <- sigma_pp * invCG
  V[2,4] <- V[4,2] <- sigma_yy * invCG
  V[1,4] <- V[4,1] <- sigma_py * invCG
  V[2,3] <- V[3,2] <- sigma_py * invCG
  
  grad <- c(g1 * b2 / b1^2, -g1 / b1, -b2 / b1, 1) # Gradient Vector
  
  var_tau <- as.numeric(t(grad) %*% V %*% grad)
  se_tau  <- sqrt(var_tau)
  
  z_stat  <- tau / se_tau
  p_value <- 2 * (1 - pnorm(abs(z_stat)))
  z       <- qnorm(1 - (1 - conf_level) / 2)
  ci      <- tau + c(-z, z) * se_tau
  
  cat("\n=== aDID Analytic Results ===\n")
  cat(sprintf("Tau Estimate: %.4f (SE: %.4f)\n", tau, se_tau))
  cat(sprintf("95%% CI: [%.4f, %.4f]\n", ci[1], ci[2]))
  cat(sprintf("P-value: %.4f\n", p_value))
  
  invisible(list(tau=tau, se=se_tau, z_stat=z_stat, p_value=p_value, ci=ci, delta=delta))
}