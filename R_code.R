library(readxl)
library(forecast)
library(seasonal)
library(seasonalview)
library(ggplot2)

#Import data
data <- read_xlsx("C:/Desktop/Time series/Ass 1/Deon.xlsx", col_names = TRUE)

# convert series into a TS. 
tsdata = ts(data$Ezgi, start = c(2011,1), frequency = 12)
plot(tsdata)
tsm <- ma(tsdata,order=12,centre = TRUE)
lines(tsm,col="red")

# Time variable
time_var <- time(tsdata) 

# Fit a linear model to the time series
fit_linear <- lm(tsdata ~ time(tsdata))
summary(fit_linear)
linear_preds <- predict(fit_linear)

# fit Quadratic model
fit_quadratic <- lm(tsdata ~ time_var + I(time_var^2))
summary(fit_quadratic)
quad_preds <- predict(fit_quadratic)

# fit Exponential model
log_tsdata <- log(tsdata)  # Transform the response variable
fit_exponential <- lm(log_tsdata ~ time_var)
summary(fit_exponential)
exp_preds <- exp(predict(fit_exponential))

# data frame to visualize all the three models
data_for_plot <- data.frame(
  Time = time(tsdata),
  Actual = as.numeric(tsdata),
  Linear_Fit = as.numeric(linear_preds),
  Quadratic_Fit = as.numeric(quad_preds),
  Exponential_Fit = as.numeric(exp_preds)
)
ggplot(data_for_plot, aes(x = Time)) +
  geom_line(aes(y = Actual, color = "Actual Data"), linetype = "solid") +
  geom_line(aes(y = Linear_Fit, color = "Linear Fit"), linetype = "solid") +
  geom_line(aes(y = Quadratic_Fit, color = "Quadratic Fit"), linetype = "solid") +
  geom_line(aes(y = Exponential_Fit, color = "Exponential Fit"), linetype = "solid") +
  theme_minimal() +
  labs(y = "tsdata", x = "Time", title = "Time Series with Model Fits") +
  theme(legend.position="top") +
  scale_color_manual( "Legend",
                     values = c("Actual Data" = "black", 
                                "Linear Fit" = "red", 
                                "Quadratic Fit" = "blue", 
                                "Exponential Fit" = "green")) +
  guides(colour = guide_legend(override.aes = list(linetype = c("solid", "solid", "solid", "solid"))))+
  scale_y_continuous(breaks = seq(500, 4000, by = 500)) # Custom y-axis


# multiplicative decomposition of data
tsdata %>% decompose(type="multiplicative") %>%
  autoplot() + xlab("Month") +
  ggtitle("Decomposition of Time series")


#Holt-winters smoothing
fit3 <- hw(tsdata,h=12)
autoplot(fit3, xlab = "Month", ylab = "Trade")
summary (fit3)

#x11 decomposition
tsdata %>% seas(x11="") -> fit
autoplot(fit) + ggtitle("X11 decomposition of Trade")

#seasonally adjusted plot
autoplot(tsdata, series="Data") +
  autolayer(trendcycle(fit), series="Trend") +
  autolayer(seasadj(fit), series="Seasonally Adjusted") +
  xlab("Year") + ylab("New orders index") +
  ggtitle("Trade") +
  scale_colour_manual(values=c("green","blue","red"),
                      breaks=c("Data","Seasonally Adjusted","Trend"))

#Monthly seasonal patterns
fit %>% seasonal() %>% ggsubseriesplot() + ylab("Seasonal")

#naive forecasting
fit <- stl(tsdata, s.window="periodic", robust=TRUE)
fit %>% seasadj() %>% naive() %>%
  autoplot() + ylab("Trade") +
  ggtitle("Naive forecasts of seasonally adjusted data")

#STL + random walk forecast
fcast <- stlf(tsdata, method='naive', h=12, level=95)
autoplot(fcast)+ylab("Forecast Reseasonalised")
summary(fcast)



