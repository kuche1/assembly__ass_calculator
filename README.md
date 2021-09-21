# assembly__shit_calculator

bash \
as -o res.o calculate.s && ld res.o && ./a.out ; echo ~$? 

fish \
as -o res.o calculate.s && ld res.o && ./a.out ; echo ~$status 
