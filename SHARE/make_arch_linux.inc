#######################################################################
#            Define Basic Utilities
#######################################################################
  SHELL = /bin/zsh
  PWD1 = `pwd`
  MYHOME = $(HOME)/bin
  PRECOMP:= /usr/bin/cpp -traditional -DLINUX
  COMPILE = $(FC)
  COMPILE_FREE = $(FC) -ffree-form -ffree-line-length-none -ffixed-line-length-none
  LINK    = ld $(FLAGS) -o
  LINK_AR = ar -ruv
  LINK_C  = $(CC) -shared -Wl,-z-defs

#######################################################################
#            Define Compiler Flags
#######################################################################
  FLAGS_R = -O2 -fexternal-blas -fallow-argument-mismatch
  FLAGS_D = -g -O0 -fexternal-blas -fbacktrace -fcheck=all -fallow-argument-mismatch
  LIBS    = -L/usr/lib -lblas -llapack -lscalapack

#######################################################################
#            MPI Options
#######################################################################
  LMPI    = T
  MPI_COMPILE = mpif90
  MPI_COMPILE_FREE = mpif90 -ffree-form \
                     -ffree-line-length-none -ffixed-line-length-none
  MPI_COMPILE_C = mpicc.openmpi
  MPI_LINK = mpif90
  MPI_RUN = mpiexec
  MPI_RUN_OPTS = -np 4
#  MPI_RUN_OPTS_SM = -np 16
#  MPI_RUN_OPTS_MD = -np 64
#  MPI_RUN_OPTS_LG = -np 256

#######################################################################
#            NAG Options
#######################################################################
  LNAG = F
  NAG_LIB = -L$(NAG_ROOT)/lib -lnag_nag

#######################################################################
#            NETCDF Options
#######################################################################
  LNETCDF = T
  NETCDF_INC = -I/usr/include
  NETCDF_LIB = -L/usr/lib -lnetcdf -lnetcdff

#######################################################################
#            NTCC Options
#######################################################################
  LNTCC = F
  NTCC_INC = -I/usr/include
  NTCC_LIB = -L/usr/lib -laladdinsub -lr8slatec -ladpak\
             -lcppsub -lcomput -lpspline -lportlib -lezcdf -lmds_sub \
             -lmdstransp -lvaxonly

#######################################################################
#            HDF5 Options
#######################################################################
  LHDF5 = T
  HDF5_INC = -I/usr/include
  HDF5_LIB = -L/usr/lib \
             -lhdf5 -lhdf5hl_fortran -lhdf5_hl -lhdf5_fortran

#######################################################################
#             PGPLOT Options
#######################################################################
  LPGPLOT = F
  PGPLOT_INC = -I$(PGPLOT_DIR)
  PGPLOT_LIB = -L$(PGPLOT_DIR) -lpgplot -L/usr/lib/x86_64-linux-gnu -lX11

#######################################################################
#             SILO Options
#######################################################################
  LSILO = F
  SILO_INC = -I$(SILOHOME)/include
  SILO_LIB = -L$(SILOHOME)/lib/x86_64-linux-gnu -lsiloh5

#######################################################################
#            FFTW3 Options
#######################################################################
  LFFTW3 = F
  FFTW3_INC = 
  FFTW3_LIB = 

#######################################################################
#            DKES/NEO Options
#######################################################################
  LDKES = T
  LNEO  = T

#######################################################################
#            GENE Options
#######################################################################
  LGENE = F
  GENE_INC = -I$(GENE_PATH)
  GENE_DIR = $(GENE_PATH)
  LIB_GENE = libgene.a
  GENE_LIB = $(GENE_DIR)/$(LIB_GENE) \
             -L/u/slazerso/src/GENE17_2016/external/pppl_cluster/futils/src -lfutils \
             -L$(FFTWHOME)/lib -lfftw3 \
             -L$(SLEPC_DIR)/$(PETSC_ARCH)/lib -lslepc \
             -L$(PETSC_DIR)/$(PETSC_ARCH)/lib -lpetsc -lX11

#######################################################################
#            COILOPT++ Options
#######################################################################
  LCOILOPT = F
  COILOPT_INC = -I$(COILOPT_PATH)
  COILOPTPP_DIR = $(COILOPT_PATH)
  LIB_COILOPTPP = libcoilopt++.a
  COILOPT_LIB = $(COILOPT_PATH)/$(LIB_COILOPTPP) \
                -L$(GSLHOME)/lib/x86_64-linux-gnu -lgsl -lgslcblas -lstdc++ -lmpi_cxx

#######################################################################
#            TERPSICHORE Options
#######################################################################
  LTERPSICHORE= F
  TERPSICHORE_INC = -I$(TERPSICHORE_PATH)
  TERPSICHORE_DIR = $(TERPSICHORE_PATH)
  LIB_TERPSICHORE = libterpsichore.a
  TERPSICHORE_LIB = $(TERPSICHORE_DIR)/$(LIB_TERPSICHORE)

#######################################################################
#            TRAVIS Options
#######################################################################
  LTRAVIS= F
  TRAVIS_DIR = $(TRAVIS_PATH)
  LIB_TRAVIS = libtravis64_sopt.a
  LIB_MCONF  = libmconf64.a
  TRAVIS_LIB = $(TRAVIS_DIR)/lib/$(LIB_TRAVIS) \
               $(TRAVIS_DIR)/mag_conf/lib/$(LIB_MCONF) -lstdc++

#######################################################################
#            REGCOIL Options
#######################################################################
  LREGCOIL= F
  REGCOIL_DIR = $(REGCOIL_PATH)
  REGCOIL_INC = -I$(REGCOIL_DIR) 
  LIB_REGCOIL = libregcoil.a
  REGCOIL_LIB = $(REGCOIL_DIR)/$(LIB_REGCOIL) -fopenmp

#######################################################################
#            LIBSTELL Shared Options
#######################################################################
#LIB_SHARE = $(BLASHOME)/lib/libblas.so \
          $(SCALAPACK_HOME)/lib/libscalapack-openmpi.so \
          $(BLACS_HOME)/lib/libblacs-openmpi.so  $(BLACS_HOME)/lib/libblacsCinit-openmpi.so $(BLACS_HOME)/lib/libblacsF77init-openmpi.so \
          $(HDF5_HOME)/lib/x86_64-linux-gnu/libhdf5_hl.so $(HDF5_HOME)/lib/x86_64-linux-gnu/libhdf5_fortran.so $(HDF5_HOME)/lib/x86_64-linux-gnu/libhdf5hl_fortran.so $(HDF5_HOME)/lib/x86_64-linux-gnu/libhdf5.so \
          $(HDF5_HOME)/lib/x86_64-linux-gnu/libmpi_usempif08.so $(HDF5_HOME)/lib/x86_64-linux-gnu/libhdf5_openmpi_fortran.so \
          $(NETCDF_HOME)/lib/x86_64-linux-gnu/libnetcdf.so $(NETCDF_HOME)/lib/x86_64-linux-gnu/libnetcdff.so $(NETCDF_HOME)/lib/x86_64-linux-gnu/libnetcdf_c++.so \
          $(SILOHOME)/lib/x86_64-linux-gnu/libsiloh5.so \
          $(GSLHOME)/lib/x86_64-linux-gnu/libgsl.so \
          $(GCC6_HOME)/libgfortran.so $(GCC6_HOME)/libstdc++.so \
          $(MPIHOME)/lib/x86_64-linux-gnu/libmpi.so $(MPIHOME)/lib/x86_64-linux-gnu/libmpi_mpifh.so \
          /usr/lib/x86_64-linux-gnu/libm.so /usr/lib/liblapack.so /usr/lib/x86_64-linux-gnu/libdl.so
#LIB_SHARE = $(BLASHOME)/lib/libblas.so \
          $(SCALAPACK_HOME)/lib/libscalapack-openmpi.so.1 \
          $(BLACS_HOME)/lib/libblacs-openmpi.so.1 \
          $(BLACS_HOME)/lib/libblacsCinit-openmpi.so.1 \
          $(BLACS_HOME)/lib/libblacsF77init-openmpi.so.1 \
          $(HDF5_HOME)/lib/x86_64-linux-gnu/libhdf5_openmpi_fortran.so \
          $(NETCDF_HOME)/lib/libnetcdf.so \
          $(NETCDF_HOME)/lib/libnetcdff.so \
          $(NETCDF_HOME)/lib/libnetcdf_c++.so \
          $(SILOHOME)/lib/x86_64-linux-gnu/libsiloh5.so \
          $(GSLHOME)/lib/x86_64-linux-gnu/libgsl.so \
          $(GCC49_HOME)/libgfortran.so \
          $(GCC49_HOME)/libstdc++.so \
          $(MPIHOME)/lib/libmpi.so \
          $(MPIHOME)/lib/libmpif77.so \
          /usr/lib/x86_64-linux-gnu/libm.so \
          /usr/lib/liblapack.so \
          /usr/lib/x86_64-linux-gnu/libdl.so

