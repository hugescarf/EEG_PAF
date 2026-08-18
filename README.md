This is a pipeline that I have developed based on the article by Furman(2018). 
The pipeline follows EEGlab preprocessing, and fieldtrip PAF calculation.
1. **Preprocessing**: notch filter, band pass filter in 1-30Hz, ICA, and manual quality check of the EEG data.
2. **Epoching**: separates eyes-open session and eyes-closed session, as well as epoching for every 5s as an analysis interval.
3. **PAFanalysis**: can be done by channel or component.
4. **Plotting**: bar diagram of eyes-open session and eyes-closed session by paired t-test.



Citation:
Furman AJ, Meeker TJ, Rietschel JC, Yoo S, Muthulingam J, Prokhorenko M, Keaser ML, Goodman RN, Mazaheri A, Seminowicz DA. Cerebral peak alpha frequency predicts individual differences in pain sensitivity. Neuroimage. 2018 Feb 15;167:203-210. doi: 10.1016/j.neuroimage.2017.11.042. Epub 2017 Nov 21. PMID: 29175204.
