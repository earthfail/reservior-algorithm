# reservoir-algorithm
reservoir is a probabilistic algorithm to sample `k` elements from a stream of elements.
It is a first for me to debug a probabilistic algorithm because I needed to use statistical methods on top of regular methods to verify 
that the algorirm works correctly.

# stack used
- emacs for coding
- [zig](https://ziglang.org) for writing the algorithm
- R and Rstudio and emacs to test the output and catch bugs

# process
I read the algorithm throughly to get an understanding of the ideas and skimmed other sources to verify my intuition. I then tried to prove the statements
in the wikipedia article are correct which was good refresher for my probabilty class.

I then looked for an unbiased [PRNG](https://www.pcg-random.org/) in zig standard library and found [Romu](https://www.romu-random.org/) which [passess](https://www.pcg-random.org/posts/pcg-passes-practrand.html) many benchmarks and was satisfied
by trusting pcg-random because I found it as a reliable source before. In the end it I used the default PRNG in zig because that was what I was comfortable with and it didn't effect the results.

I choose to sample 5 elements out of 10 becuase 2^10 is approx 1000 and if I sampled 10^5 each time I expected it to not take alot of time (I didn't want to wait between debugging cycles) and each
set would get sampled at least 100 times. Moreover, I can encode each set as [bitset](https://en.cppreference.com/w/cpp/utility/bitset.html) and would be easy to handle in R as a number.
In the end I made 8 runs each with 10^5 samples.

In Rstudio I used tidyverse to explore the data and make sure it is reasonable. And used dplyr package to accumulate the data in one dataframe and calculate [chi square](https://en.wikipedia.org/wiki/Pearson%27s_chi-squared_test) statistic
to compare the observations to a uniform distribution.

# results
the p-value is 0.98 which means it is highly likey the observation comes from a uniform distribution. I didn't make a visualization but I didn't another test by calculating the probability of x being in a random subset of size 5
and it matched the theory (prob = 0.5).

# reflect
- emacs was really helpful in visualizing and general calculations with calc-mode and it saved me from having to write a tool to convert the numbers to binary and back. Eventhough it is a simple task but piping the data is cumbersome.
- the expressions for uniform and geometric distributions in the algorithms are not intuitive and I should have considered sacrificed numerical stability and using a standard form.
- The indices in the algorithm run from 1 to n inclusive and eventhough I noticed it the first time and make a mental note to myself, I still got a bug in the code which I only catched when visualizing the samples in Rstudio.
- zig is currently changing its io api and it is very painful, specially so because it is "source is documentation" aahh documentation. I wish C just had basic modules like Odin or Zig or for Zig to be stabe again.
- If I had more time I would like to pass arguments to the zig code and R code but since I am not accustomed to R or the standard my code is a basic jupyter notebook style.
  Maybe next time make a more streamlined (haha) pipeline to speedup testing.
- I love probability theory. statistics is still hard specially checking the assumptions and finding a good book ;)
