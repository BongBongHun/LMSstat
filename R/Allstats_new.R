#' Automatically processes T-test, U-test, Anova, Scheffe(Anova Post-Hoc), Krukal Wallis, Dunn-test(BH adjusted,(Kurkal Wallis Post-Hoc)) while allowing adjustment of FDR
#'
#' @param Data csv file with Header as False First column with Sample Second column with Multilevel(Mixomics) so that it can be compatible with other multivariate statistics Third column with Group information. Rest of the columns are the metabolites to be tested.
#' @param Adjust_p_value Set True if FDR adjustments are to be made. If not set False
#' @param Adjust_method adjustment methods frequently used. "holm", "hochberg", "hommel", "bonferroni", "BH", "BY","fdr", "none"
#'
#' @return List including Result Matrix of p-values, converted datas.
#' @export
#'
#' @examples data(Data)
#' Result <- Allstats_new(Data)
Allstats_new <- function(Data, Adjust_p_value = T, Adjust_method = "BH") {
  LETTERS210729 <- paste0("V", 1:500000)
  colnames(Data) <- Data[1, ]
  Data <- Data[-1, -2]
  Data <- Data %>% dplyr::arrange(Data$Group)
  Data_renamed <- Data
  nmet <- ncol(Data) - 2
  colnames(Data_renamed) <- c(colnames(Data[1:2]), LETTERS210729[1:nmet])
  rownames(Data_renamed) <- Data[, 1]
  Data_renamed_raw <- Data_renamed[, -c(1, 2)]
  Data_renamed_raw <- apply(Data_renamed_raw, 2, as.numeric)
  Data_final <- cbind(Data[, 1:2], Data_renamed_raw)
  Data_tmp <- data.table::as.data.table(Data_final)
  Data_tmp1 <- Data_tmp
  Data_tmp1$Group <- as.factor(Data_tmp1$Group)



  if (length(unique(Data_final$Group)) == 2) {
    groups_split <- split(Data_tmp, Data_tmp$Group)

    #### ttest ####
    split_t_test <- function(x, i) {
      if (var(groups_split[[x[1]]][[i]]) == 0 & var(groups_split[[x[2]]][[i]]) == 0) {
        1
      } else {
        t.test(
          groups_split[[x[1]]][[i]],
          groups_split[[x[2]]][[i]]
        )[["p.value"]]
      }
    }


    res_ttest <- lapply(
      (seq_len(ncol(Data_tmp) - 2) + 2),
      function(i) as.list(combn(names(groups_split), 2, split_t_test, i = i))
    )


    df_ttest <- data.table::rbindlist(res_ttest)
    Result <- df_ttest
    print("T-test has finished")

    #### utest ####
    split_u_test <- function(x, i) {
      if (var(groups_split[[x[1]]][[i]]) == 0 & var(groups_split[[x[2]]][[i]]) == 0) {
        if (groups_split[[x[1]]][[i]] == groups_split[[x[2]]][[i]]) {
          1
        } else {
          wilcox.test(
            groups_split[[x[1]]][[i]],
            groups_split[[x[2]]][[i]]
          )[["p.value"]]
        }
      } else {
        wilcox.test(
          groups_split[[x[1]]][[i]],
          groups_split[[x[2]]][[i]]
        )[["p.value"]]
      }
    }
    res_utest <- lapply(
      (seq_len(ncol(Data_tmp) - 2) + 2),
      function(i) as.list(combn(names(groups_split), 2, split_u_test, i = i))
    )
    df_utest <- data.table::rbindlist(res_utest)
    Result <- cbind(Result, df_utest)
    print("U-test has finished")

    ### finalization ####
    Result <- as.matrix(Result)

    Names <- NULL
    for (i in 1:choose(length(groups_split), 2)) {
      Names <- rbind(Names, paste(combn(names(groups_split), 2)[1, i],
        combn(names(groups_split), 2)[2, i],
        sep = "-"
      ))
    }

    rownames(Result) <- colnames(Data)[3:(ncol(Data_final))]
    colnames(Result) <- c(paste(Names, "t-test",
      sep = "___"
    ), paste(Names, "u-test",
      sep = "___"
    ))
    if (Adjust_p_value == T) {
      print("###########################################")
      print(paste0(
        "adjusted according to the ",
        Adjust_method, " method"
      ))
      print("###########################################")
      Result <- apply(Result, 2, function(x) {
        p.adjust(x, method = Adjust_method)
      })
    } else {
      print("###########################################")
      print("p_value not adjusted")
      print("###########################################")
    }
    rm(list = setdiff(ls(), c(
      "Data_renamed", "Data",
      "Result", "LETTERS210729", "event",
      "P_hoc", "Colors", "significant_variable_only"
    )))
    print("statistical test has finished")
    Result_T <- Result[, 1]
    Result_U <- Result[, 2]
    print("subsets have been made")
    Final <- list()
    Final$Data <- Data
    Final$Data_renamed <- Data_renamed
    Final$Result <- Result
    Final$t_test <- Result_T
    Final$u_test <- Result_U
    Final
  } else if (length(unique(Data_final$Group)) > 2) {
    groups_split <- split(Data_tmp, Data_tmp$Group)

    #### ttest ####
    split_t_test <- function(x, i) {
      if (var(groups_split[[x[1]]][[i]]) == 0 & var(groups_split[[x[2]]][[i]]) == 0) {
        1
      } else {
        t.test(
          groups_split[[x[1]]][[i]],
          groups_split[[x[2]]][[i]]
        )[["p.value"]]
      }
    }

    res_ttest <- lapply(
      (seq_len(ncol(Data_tmp) - 2) + 2),
      function(i) as.list(combn(names(groups_split), 2, split_t_test, i = i))
    )
    df_ttest <- data.table::rbindlist(res_ttest)
    Result <- df_ttest
    print("T-test has finished")

    #### utest ####
    split_u_test <- function(x, i) {
      if (var(groups_split[[x[1]]][[i]]) == 0 & var(groups_split[[x[2]]][[i]]) == 0) {
        if (groups_split[[x[1]]][[i]] == groups_split[[x[2]]][[i]]) {
          1
        } else {
          wilcox.test(
            groups_split[[x[1]]][[i]],
            groups_split[[x[2]]][[i]]
          )[["p.value"]]
        }
      } else {
        wilcox.test(
          groups_split[[x[1]]][[i]],
          groups_split[[x[2]]][[i]]
        )[["p.value"]]
      }
    }
    res_utest <- lapply(
      (seq_len(ncol(Data_tmp) - 2) + 2),
      function(i) as.list(combn(names(groups_split), 2, split_u_test, i = i))
    )
    df_utest <- data.table::rbindlist(res_utest)
    Result <- cbind(Result, df_utest)
    print("U-test has finished")

    #### ANOVAPostHoc ####
    formula_anova <- lapply(colnames(Data_tmp)[3:ncol(Data_tmp)], function(x) as.formula(paste0(x, " ~ Group")))
    res_anova <- lapply(formula_anova, function(x) summary(aov(x, data = Data_tmp)))
    names(res_anova) <- format(formula_anova)
    p_anova <- unlist(lapply(res_anova, function(x) x[[1]]$"Pr(>F)"[1]))

    df_anova <- data.table::data.table(p_anova)
    Result <- cbind(Result, df_anova)

    anovapost_name <- lapply(colnames(Data_tmp)[3:ncol(Data_tmp)], function(x) as.formula(paste0(x, " ~ Group")))
    res_anovapost <- lapply(anovapost_name, function(x) DescTools::PostHocTest(aov(x, data = Data_tmp), method = "scheffe"))
    names(res_anovapost) <- format(anovapost_name)
    post_anova <- lapply(res_anovapost, function(x) x[["Group"]][, 4])

    df_anova_post <- data.frame(post_anova)
    Result <- cbind(Result, t(df_anova_post))

    print("Anova & PostHoc has finished")


    #### KruskalWallisPostHoc ####
    formula_kw <- lapply(colnames(Data_tmp)[3:ncol(Data_tmp)], function(x) as.formula(paste0(x, " ~ Group")))
    res_kw <- lapply(formula_anova, function(x) kruskal.test(x, data = Data_tmp)[["p.value"]])
    names(res_kw) <- format(formula_kw)
    p_kw <- unlist(res_kw)

    df_kw <- data.table::data.table(p_kw)
    Result <- cbind(Result, df_kw)

    kwpost_name <- lapply(colnames(Data_tmp)[3:ncol(Data_tmp)], function(x) as.formula(paste0(x, " ~ Group")))
    res_kwpost <- lapply(kwpost_name, function(x) FSA::dunnTest(x, data = Data_tmp1, method = "none"))
    names(res_kwpost) <- format(kwpost_name)
    post_kw <- lapply(res_kwpost, function(x) x[["res"]][["P.unadj"]])
    post_kw <- lapply(post_kw, function(x) p.adjust(x, method = "BH"))

    df_kw_post <- t(data.table::data.table(data.frame(post_kw)))
    Result <- cbind(Result, df_kw_post)

    print("Kruskal Wallis & PostHoc has finished")

    #### finalization ####
    Result <- as.matrix(Result)

    Names <- NULL
    for (i in 1:choose(length(groups_split), 2)) {
      Names <- rbind(Names, paste(combn(names(groups_split), 2)[1, i],
        combn(names(groups_split), 2)[2, i],
        sep = "-"
      ))
    }

    AN_Post_names <- rownames(df_anova_post)
    DU_post_names <- res_kwpost[[1]]$res$Comparison

    rownames(Result) <- colnames(Data)[3:(ncol(Data_final))]
    colnames(Result) <- c(
      paste(Names[, 1], "t-test",
        sep = "___"
      ), paste(Names[, 1], "u-test",
        sep = "___"
      ), "Anova", paste(AN_Post_names,
        "ANO_posthoc",
        sep = "___"
      ), "Kruskal_Wallis",
      paste(DU_post_names, "Kru_posthoc(Dunn)",
        sep = "___"
      )
    )

    Result_Ano_P <- Result[, (2 * choose(
      length(unique(Data$Group)),
      2
    ) + 2):(3 * choose(length(unique(Data$Group)), 2) +
      1)]
    Result_Kru_P <- Result[, (3 * choose(
      length(unique(Data$Group)),
      2
    ) + 3):(4 * choose(length(unique(Data$Group)), 2) +
      2)]

    if (Adjust_p_value == T) {
      print("###########################################")
      print(paste0(
        "adjusted according to the ",
        Adjust_method, " method"
      ))
      print("###########################################")
      Result <- apply(Result, 2, function(x) {
        p.adjust(x, method = Adjust_method)
      })
    } else {
      print("###########################################")
      print("p_value not adjusted")
      print("###########################################")
    }
    rm(list = setdiff(ls(), c(
      "Data_renamed", "Data",
      "Result", "LETTERS210729", "event",
      "P_hoc", "Colors", "significant_variable_only", "Result_Ano_P", "Result_Kru_P"
    )))
    print("statistical test has finished")

    Result[, (2 * choose(length(unique(Data$Group)), 2) + 2):(3 * choose(length(unique(Data$Group)), 2) + 1)] <- Result_Ano_P
    Result[, (3 * choose(length(unique(Data$Group)), 2) + 3):(4 * choose(length(unique(Data$Group)), 2) + 2)] <- Result_Kru_P

    Result_T <- Result[, 1:choose(
      length(unique(Data$Group)),
      2
    )]
    Result_U <- Result[, (choose(
      length(unique(Data$Group)),
      2
    ) + 1):(2 * choose(length(unique(Data$Group)), 2))]
    Result_Ano <- as.data.frame(Result[, (2 * choose(length(unique(Data$Group)), 2) + 1):(2 * choose(length(unique(Data$Group)), 2) + 1)])
    colnames(Result_Ano) <- colnames(Result)[(2 * choose(
      length(unique(Data$Group)),
      2
    ) + 1)]
    Result_Kru <- as.data.frame(Result[, (3 * choose(
      length(unique(Data$Group)),
      2
    ) + 2):(3 * choose(length(unique(Data$Group)), 2) +
      2)])
    colnames(Result_Kru) <- colnames(Result)[(3 * choose(
      length(unique(Data$Group)),
      2
    ) + 2)]
    print("subsets have been made")
    Final <- list()
    Final$Data <- Data
    Final$Data_renamed <- Data_renamed
    Final$Result <- Result
    Final$Anova <- Result_Ano
    Final$Anova_PostHoc <- Result_Ano_P
    Final$KW <- Result_Kru
    Final$Dunn <- Result_Kru_P
    Final$t_test <- Result_T
    Final$u_test <- Result_U
    Final
  }
}
