mkdir us5
cd us5/
ln -s ../data/md5.rst md.rst
bash ../scripts/setup_umb_samp.sh
bash run_umb_samp.sh
wait
cpptraj < ../data/make_us_trj.in &> make_us_trj.log
wait
cd ..
mkdir adiab5
cd adiab5
ln -s ../us5/rc-0.30/md1ps.rst md1ps_rc-0.3.rst
bash ../scripts/run_adiab_all.sh
wait
cpptraj < ../data/make_adiab_trj.in &> make_adiab_trj.log
wait
