# Bootstrap on Eddy Covariance

Patrizia Favaron

## Introduction

This lab note describes my "discoveries" in implementing bootstrap on the MeteoFlux&trade; system. Focus is on implementation details, and the description level is non-scientific: not directly useful for my paper!

I claim it *is* useful anyway. To me, for present and future reference.

## Reference implementation and real-world data

The reference implementation of my bootstrap routine has been tested against synthetic normal and log-normal data. Theoretical (possibly approximate) and bootstrap confidence intervals on the mean have been compared and found "right".

I had no evidence on what happens in an eddy-covariance system, and this is the attempt to gain something of it.

Overall, from the preceding artificial experience I can say I transitioned from a "I don't believe." to an "I will believe only if I see it", to a "The Band! The Band! Jesus Christ made me this grace! God Bless the United States of America!" of Jake after having been hit by the blue ray in The Blues Brothers.

Now here I am, basically doing my best to "organize the show", after sources have been transferred to my Nvidia Orin Nano MeteoFlux instance.

The first step consists in reading (at will) one hour of actual data, and performing some test on them.

The hourly file is:

```
/home/patti/Documents/Research/Congresso_2026_Poster_Reynolds/data/Pieve/20130401.13R
```

On run the reference implementation, now activated independently and separately on $u$, $v$, $w$ and $t$, took 1.08s for single call (4.32s for all the calls).

In this case it was $n=m=36000$, with the number of samples $n_s=2000$.

## Is the system spending more time extracting uniform deviates, or building samples?

On the web I've seen a specific bootstrap implementation (the one I got inspiration from) in which the deviate generation and the actual sample construction were separated. The former then was executed sequentially, while the latter occurred in parallel among some "CPU"s.

I wonder whether this is something on which I could investigate a little bit more.

to test for this idea I instrumented the reference implementation with code for computing the time spent in generating random numbers, sampling and (yes, I overlooked it) sorting. Then I accumulated the homologous times along the bootstrap calls, and averaged them out scaling to times per sample. Here are the results on the test hour:

| Activity                             | Time (s) |
| ------------------------------------ | -------: |
| Time spent generating random numbers |    0.400 |
| Time spent managing samples          |    0.694 |
| Time spent sorting                   |    0.000 |

So, the time spent generating random numbers is quite high compared to sample management and generation. The last time, spent "sorting", takes a time which is entirely negligible.

In conclusion, the idea of parallelizing only the sampling phase may result in below-than-optimal performances.

## Merging quadruple components evaluation

A first performance gain can be in principle obtained by doing random generation once, and then using it separately on the quadruple components taken together.

This approach moves the code away significantly from the reference implementation, but is worth a try.

The new implementation, in routine boot_multi_mean, got the following execution times:

| Activity                             | Time (s) |
| ------------------------------------ | -------: |
| Time spent generating random numbers |    0.401 |
| Time spent managing samples          |    4.295 |
| Time spent sorting                   |    0.000 |

As anticipated and hoped, the extraction of random numbers is now made only once, and employed on all channels.

Interestingly, however, the execution time of sampling resulted in an execution time more than 50% *slower* than the time taken by the total sampling time performed on individual quadruple components separately.

