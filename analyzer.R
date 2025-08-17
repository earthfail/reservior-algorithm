install.packages("tidyverse")
# install.packages("dplyr")
library(readr)
library(dplyr)
library(magrittr)

data1 <- read_csv("r01.txt")
data2 <- read_csv("r02.txt")
data3 <- read_csv("r03.txt")
data4 <- read_csv("r04.txt")
data5 <- read_csv("r05.txt")
data6 <- read_csv("r06.txt")
data7 <- read_csv("r07.txt")
data8 <- read_csv("r08.txt")

total_data <- data1 %>% 
  mutate(count = count + data2$count) %>% 
  mutate(count = count + data3$count) %>% 
  mutate(count = count + data4$count) %>% 
  mutate(count = count + data5$count) %>% 
  mutate(count = count + data6$count) %>% 
  mutate(count = count + data7$count) %>% 
  mutate(count = count + data8$count)

p <- factorial(5)*factorial(5) / factorial(10)
n <- 100000 * 8
np <- p * n

# used to calculate the sum: \sum_{i=1}^k \frac{x_i^2}{m_i}
# where x_i is the number of observations for category i and in our case
# a subset of size 5 out of 10 elements. and m_i the the expected value which
# is n * p
total_data_m <- total_data %>% mutate(m = np, s = count^2 / m)
degrees_of_freedom <- factorial(10)/(factorial(5)*factorial(5)) - 1
dof <- degrees_of_freedom
chi2 = sum(total_data_m$s) - n

# using the approximation 1-CDF(x;k)\leq (x/k exp(1-x/k))^{k/2} because I can't
# bother finding "lower incomplete gamma function" or figuring out chisq.test
# at 1am. I hope I got it right.
pvalue <- ((chi2/dof)*exp(1-chi2/dof))^{dof/2}


filter_zeros <- function(d) {
  d %>% filter(count == 0)
}

# sample geometric distribution like in code
n <- 100000
u <- runif(n)
p <- 0.1
w <- floor(log(u)/log(1-p))
z <- w + 1
# mean(z) ~ 10 just eye balling it (if you know you know)