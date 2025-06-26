# Habitat suitability model cells analysis

## Cells parameters, inputs and outputs

### `02_download_presences.R`

| Parameters   |
|--------------|
| `aphiaid`    |
| `bbox`       |
| `datadir`    |
| `study_area` |

| Inputs |
|--------|
|        |

| Outputs              |
|----------------------|
| `datasets_all.csv`   |
| `mydata_eurobis.RDS` |
| `study_area.RDS`     |

### `03_download_environment.R`

| Parameters                                                                |
|---------------------------------------------------------------------------|
| `datadir`                                                                 |
| `envdir`                                                                  |
| `date_start` (🔺 listed as input, should be converted with `as_datetime`) |
| `date_end` (🔺 listed as input, should be converted with `as_datetime`)   |

| Inputs           |
|------------------|
| `study_area.RDS` |

| Outputs      |
|--------------|
| `tempsal.nc` |
| `npp.nc`     |

### `04_preprocess_presences.R`

| Parameters          |
|---------------------|
| `datadir`           |
| `envdir`            |

| Inputs               |
|----------------------|
| `datasets_all.csv`   |
| `mydata_eurobis.RDS` |
| `study_area.RDS`     |
| `tempsal.nc`         |

| Outputs                  |
|--------------------------|
| `datasets_selection.csv` |
| `cleaned_data.RDS`       |
| `thinned_m.RDS`          |
| `thinned_d.RDS`          |

### `05a_sample_background.R`

| Parameters   |
|--------------|
| `study_area` |
| `envdir`     |
| `bbox`       |
| `datadir`    |
| `aphiaid`    |

| Inputs                   |
|--------------------------|
| `tempsal.nc`             |
| `datasets_selection.csv` |
| `thinned_m.RDS`          |
| `thinned_d.RDS`          |

| Outputs            |
|--------------------|
| `target_group.RDS` |

### `05b_sample_background.R`

| Parameters          |
|---------------------|
| `datadir`           |
| `study_area`        |
| `envdir`            |

| Inputs                   |
|--------------------------|
| `tempsal.nc`             |
| `datasets_selection.csv` |
| `thinned_m.RDS`          |
| `thinned_d.RDS`          |
| `target_group.RDS`       |

| Outputs                                      |
|----------------------------------------------|
| `pback_month.RDS`                            |
| `pback_decade.RDS`                           |
| `thinned_tg_m.RDS` (not used in later cells) |
| `thinned_tg_d.RDS` (not used in later cells) |

### `06_extract_environment.R`

| Parameters |
|------------|
| `datadir`  |
| `envdir`   |
| `bbox`     |

| Inputs             |
|--------------------|
| `tempsal.nc`       |
| `npp.nc`           |
| `pback_month.RDS`  |
| `pback_decade.RDS` |

| Outputs                                                        |
|----------------------------------------------------------------|
| `mean_npp.nc` (only used by the cell itself--cache)            |
| `bathy.nc` (🔺 not listed as output in comments)               |
| `env_month.RDS` (🔺 used in 09, but loaded as env_month.RData) |
| `env_decade.RDS`                                               |
| `thetao_avg_m.nc`                                              |
| `so_avg_m.nc`                                                  |
| `npp_avg_m.nc`                                                 |
| `thetao_avg_d.nc`                                              |
| `so_avg_d.nc`                                                  |
| `npp_avg_d.nc`                                                 |

### `07_PAExploration.R`

| Parameters   |
|--------------|
| `study_area` |
| `datadir`    |
| `aphiaid`    |
| `figdir`     |

| Inputs             |
|--------------------|
| `cleaned_data.RDS` |

| Outputs                                                  |
|----------------------------------------------------------|
| `spatial_decade{aphiaid}.png` (not used in later cells)  |
| `temporal_decade{aphiaid}.png` (not used in later cells) |
| `spatial_month{aphiaid}.png` (not used in later cells)   |
| `temporal_month{aphiaid}.png` (not used in later cells)  |

### `08_ensemble_decade.R`

| Parameters     |
|----------------|
| `datadir`      |

| Inputs           |
|------------------|
| `env_decade.RDS` |

| Outputs                           |
|-----------------------------------|
| `modelling_decade/ranger.RDS`     |
| `modelling_decade/randforest.RDS` |
| `modelling_decade/gam.RDS`        |
| `modelling_decade/mars.RDS`       |
| `modelling_decade/maxent.RDS`     |
| `modelling_decade/xgb.RDS`        |
| `modelling_decade/stack_data.RDS` |
| `modelling_decade/stack_mod.RDS`  |
| `modelling_decade/stack_fit.RDS`  |

### `09_ensemble_month.R`

| Parameters     |
|----------------|
| `datadir`      |
| `envdir`       |

| Inputs                                                                        |
|-------------------------------------------------------------------------------|
| `bathy.nc`                                                                    |
| `env_month.RData` (they probably mean env_month.RDS, which is created by 06)  |
| `thetao_avg_m.tif` (not an output of an above cell, but mabe nc file from 06) |
| `so_avg_m.tif` (not an output of an above cell, but mabe nc file from 06)     |
| `npp_avg_m.tif` (not an output of an above cell, but mabe nc file from 06)    |

| Outputs                            |
|------------------------------------|
| `modelling_monthly/ranger.RDS`     |
| `modelling_monthly/randforest.RDS` |
| `modelling_monthly/gam.RDS`        |
| `modelling_monthly/mars.RDS`       |
| `modelling_monthly/maxent.RDS`     |
| `modelling_monthly/xgb.RDS`        |
| `modelling_monthly/stack_data.RDS` |
| `modelling_monthly/stack_mod.RDS`  |
| `modelling_monthly/stack_fit.RDS`  |

### `10_mapping_predictions.R`

| Parameters   |
|--------------|
| `datadir`    |
| `aphiaid`    |
| `envdir`     |
| `mapsdir`    |

| Inputs                            |
|-----------------------------------|
| `bathy.nc`                        |
| `thetao_avg_m.nc`                 |
| `so_avg_m.nc`                     |
| `npp_avg_m.nc`                    |
| `thetao_avg_d.nc`                 |
| `so_avg_d.nc`                     |
| `npp_avg_d.nc`                    |
| `modelling_decade/stack_fit.RDS`  |
| `modelling_monthly/stack_fit.RDS` |

| Outputs                                                                |
|------------------------------------------------------------------------|
| `HSM_{aphiaid}_ensemble_monthly_v0_1.nc`                               |
| `HSM_{aphiaid}_decade_present_v0_1.nc` (not used in later cells)       |
| `HSM_{aphiaid}_decade_future_{YYYY}_v0_1.nc` (not used in later cells) |

### `11_static_plot.R`

| Parameters   |
|--------------|
| `min_lat`    |
| `max_lon`    |
| `max_lat`    |
| `mapsdir`    |
| `figdir`     |
| `min_lon`    |
| `aphiaid`    |

| Inputs                                   |
|------------------------------------------|
| `HSM_{aphiaid}_ensemble_monthly_v0_1.nc` |

| Outputs            |
|--------------------|
| `monthly_bbox.png` |

### `12_report.Rmd`

Displays `monthly_bbox.png`

