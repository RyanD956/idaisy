######################################
##### Work in progress functions #####
######################################

# daisy_create_morris <- function(
#   parameter_list,
#   trajectories,
#   levels,
#   grid_jump
# ) {
#   morris_design <- morris(
#     model = NULL,
#     factors = parameter_list$parameter,
#     r = trajectories,
#     design = list(type = "oat", levels = levels, grid.jump = grid_jump)
#   )

#   # Scale the [0, 1] Morris design matrix to real parameter ranges
#   scale_params <- function(X, param_ranges) {
#     X_scaled <- X
#     for (i in seq_len(ncol(X))) {
#       X_scaled[, i] <- param_ranges$min[i] +
#         X[, i] * (param_ranges$max[i] - param_ranges$min[i])
#     }
#     colnames(X_scaled) <- parameter_list$parameter
#     as.data.frame(X_scaled)
#   }

#   param_df <- scale_params(morris_design$X, parameter_list) %>%
#     mutate(
#       sim_name = seq_len(nrow(morris_design$X)),
#       .before = everything()
#     ) %>%
#     # Sand is the residual texture fraction (must sum to 100 with silt + clay)
#     mutate(sand_30 = 100 - silt_30 - clay_30, .before = humus_30) %>%
#     mutate(sand_60 = 100 - silt_60 - clay_60, .before = humus_60) %>%
#     mutate(sand_100 = 100 - silt_100 - clay_100, .before = humus_100) %>%
#     # Stem fraction is the complement of leaf fraction at each growth stage
#     mutate(
#       Stem_0 = 1 - Leaf_0,
#       Stem_25 = 1 - Leaf_25,
#       Stem_50 = 1 - Leaf_50,
#       Stem_75 = 1 - Leaf_75,
#       Stem_100 = 1 - Leaf_100,
#       .after = Leaf_100
#     ) %>%
#     # Convert day-of-year integer to "MM DD" string expected by daisy
#     mutate(
#       sow_date = format(
#         ymd("2025-01-01") + days(as.integer(sow_date) - 1),
#         "%m %d"
#       )
#     ) %>%
#     # Zero fertiliser rate means no application — represent as NA for template
#     mutate(fert_rate = na_if(fert_rate, 0))

#   message("Finished creating Morris design data frame.")
#   invisible(list(morris_design = morris_design, df = param_df))
# }

# get_morris_results <- function(morris_design, output_list) {
#   morris_results <- map(names(output_list), function(output_name) {
#     morris_design <<- tell(morris_design, output_list[[output_name]])

#     tibble(
#       parameter = colnames(morris_design$ee),
#       mu = apply(morris_design$ee, 2, mean),
#       mu_star = apply(morris_design$ee, 2, function(x) mean(abs(x))),
#       sigma = apply(morris_design$ee, 2, sd)
#     )
#   }) %>%
#     set_names(names(output_list))

#   message(
#     "Morris analysis complete. Access results with e.g. morris_results$yield"
#   )
#   invisible(morris_results)
# }
