!-----------------------------------------------------------------------
!     Subroutine:    stellopt_fcn
!     Authors:       S. Lazerson (lazerson@pppl.gov)
!     Date:          05/26/2012
!     Description:   This subroutine calculates the funciton which is
!                    minimized by STELLOPT.  Originally developed for
!                    the lmdif function.
!-----------------------------------------------------------------------
      SUBROUTINE stellopt_fcn(m, n, x, fvec, iflag, ncnt)
!-----------------------------------------------------------------------
!     Libraries
!-----------------------------------------------------------------------
      USE stel_kinds, ONLY: rprec
      USE stellopt_runtime
      USE stellopt_input_mod
      USE stellopt_vars
      USE stellopt_targets
      USE equil_utils, ONLY: eval_prof_spline
      USE vmec_input
      USE vmec_params, ONLY: norm_term_flag, bad_jacobian_flag,&
                             more_iter_flag, jac75_flag, input_error_flag,&
                             phiedge_error_flag, ns_error_flag, &
                             misc_error_flag, successful_term_flag, &
                             restart_flag, readin_flag, timestep_flag, &
                             output_flag, cleanup_flag, reset_jacdt_flag
!                             animec_flag, flow_flag
      USE vmec_main, ONLY:  multi_ns_grid
      USE mpi_params                                                    ! MPI
      IMPLICIT NONE
      
!-----------------------------------------------------------------------
!     Input Variables
!        m       Number of function dimensions
!        n       Number of function variables
!        x       Vector of function variables
!        fvec    Output array of function values
!        iflag   Processor number
!        ncnt    Current function evaluation
!----------------------------------------------------------------------
      INTEGER, INTENT(in)      ::  m, n, ncnt
      INTEGER, INTENT(inout)   :: iflag
      REAL(rprec), INTENT(inout)  :: x(n)
      REAL(rprec), INTENT(out) :: fvec(m)
      
!-----------------------------------------------------------------------
!     Local Variables
!        ier         Error flag
!        iunit       File unit number
!----------------------------------------------------------------------
      LOGICAL ::  lscreen
      INTEGER ::  ier, nvar_in, dex, dex2, ik, istat, iunit, pass
      INTEGER ::  vctrl_array(5)
      REAL(rprec) :: norm_aphi, norm_am, norm_ac, norm_ai, norm_ah,&
                     norm_at, norm_ne, norm_te, norm_ti, norm_th, &
                     norm_phi, norm_zeff, temp
      INTEGER, PARAMETER     :: max_refit = 2
      REAL(rprec), PARAMETER :: ec  = 1.60217653D-19
      CHARACTER(len = 16)     :: temp_str
      CHARACTER(len = 128)    :: reset_string
      CHARACTER(len = 256)    :: ctemp_str
      
!----------------------------------------------------------------------
!     BEGIN SUBROUTINE
!----------------------------------------------------------------------
      ! Load variables first
      norm_aphi = 1; norm_am = 1; norm_ac = 1; norm_ai = 1
      norm_ah   = 1; norm_at = 1; norm_phi = 1; norm_zeff = 1
      norm_ne   = 1; norm_te = 1; norm_ti  = 1; norm_th = 1
      ! Save variables
      !CALL SLEEP(1)  ! Do this so code 'catches up'

      DO nvar_in = 1, n
         IF (var_dex(nvar_in) == iaphi .and. arr_dex(nvar_in,2) == norm_dex) norm_aphi = x(nvar_in)
         IF (var_dex(nvar_in) == iam .and. arr_dex(nvar_in,2) == norm_dex) norm_am = x(nvar_in)
         IF (var_dex(nvar_in) == iac .and. arr_dex(nvar_in,2) == norm_dex) norm_ac = x(nvar_in)
         IF (var_dex(nvar_in) == iai .and. arr_dex(nvar_in,2) == norm_dex) norm_ai = x(nvar_in)
         IF (var_dex(nvar_in) == iah .and. arr_dex(nvar_in,2) == norm_dex) norm_ah = x(nvar_in)
         IF (var_dex(nvar_in) == iat .and. arr_dex(nvar_in,2) == norm_dex) norm_at = x(nvar_in)
         IF (var_dex(nvar_in) == ine .and. arr_dex(nvar_in,2) == norm_dex) norm_ne = x(nvar_in)
         IF (var_dex(nvar_in) == izeff .and. arr_dex(nvar_in,2) == norm_dex) norm_zeff = x(nvar_in)
         IF (var_dex(nvar_in) == ite .and. arr_dex(nvar_in,2) == norm_dex) norm_te = x(nvar_in)
         IF (var_dex(nvar_in) == iti .and. arr_dex(nvar_in,2) == norm_dex) norm_ti = x(nvar_in)
         IF (var_dex(nvar_in) == ith .and. arr_dex(nvar_in,2) == norm_dex) norm_th = x(nvar_in)
         IF (var_dex(nvar_in) == iam_aux_f .and. arr_dex(nvar_in,2) == norm_dex) norm_am = x(nvar_in)
         IF (var_dex(nvar_in) == iai_aux_f .and. arr_dex(nvar_in,2) == norm_dex) norm_ai = x(nvar_in)
         IF (var_dex(nvar_in) == iphi_aux_f .and. arr_dex(nvar_in,2) == norm_dex) norm_phi = x(nvar_in)
         IF (var_dex(nvar_in) == iac_aux_f .and. arr_dex(nvar_in,2) == norm_dex) norm_ac = x(nvar_in)
         IF (var_dex(nvar_in) == ine_aux_f .and. arr_dex(nvar_in,2) == norm_dex) norm_ne = x(nvar_in)
         IF (var_dex(nvar_in) == ite_aux_f .and. arr_dex(nvar_in,2) == norm_dex) norm_te = x(nvar_in)
         IF (var_dex(nvar_in) == iti_aux_f .and. arr_dex(nvar_in,2) == norm_dex) norm_ti = x(nvar_in)
         IF (var_dex(nvar_in) == ith_aux_f .and. arr_dex(nvar_in,2) == norm_dex) norm_th = x(nvar_in)
         IF (var_dex(nvar_in) == iah_aux_f .and. arr_dex(nvar_in,2) == norm_dex) norm_ah = x(nvar_in)
         IF (var_dex(nvar_in) == iat_aux_f .and. arr_dex(nvar_in,2) == norm_dex) norm_at = x(nvar_in)
         IF (var_dex(nvar_in) == izeff_aux_f .and. arr_dex(nvar_in,2) == norm_dex) norm_zeff = x(nvar_in)
      END DO
      !CALL SLEEP(1)  ! Do this so code 'catches up'
      !temp = norm_phi+var_dex(1)  ! Think this can go away
      DO nvar_in = 1, n
         IF (arr_dex(nvar_in,2) == norm_dex) cycle
         IF (var_dex(nvar_in) == iphiedge) phiedge = x(nvar_in)
         IF (var_dex(nvar_in) == icurtor) curtor = x(nvar_in)
         IF (var_dex(nvar_in) == ipscale) pres_scale = x(nvar_in)
         IF (var_dex(nvar_in) == imixece) mix_ece = x(nvar_in)
         IF (var_dex(nvar_in) == ibcrit) bcrit = x(nvar_in)
         IF (var_dex(nvar_in) == iextcur) extcur(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iaphi) aphi(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iam) am(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iac) ac(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iai) ai(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iah) ah(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iat) at(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == ine) ne_opt(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == izeff) zeff_opt(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == ite) te_opt(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iti) ti_opt(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == ith) th_opt(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iam_aux_s) am_aux_s(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iam_aux_f) am_aux_f(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iac_aux_s) ac_aux_s(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iac_aux_f) ac_aux_f(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == ibeamj_aux_f) beamj_aux_f(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == ibootj_aux_f) bootj_aux_f(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iai_aux_s) ai_aux_s(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iai_aux_f) ai_aux_f(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iphi_aux_f) phi_aux_f(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == ine_aux_f) ne_aux_f(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == izeff_aux_f) zeff_aux_f(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == ite_aux_f) te_aux_f(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iti_aux_f) ti_aux_f(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == ith_aux_f) th_aux_f(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iah_aux_f) ah_aux_f(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iat_aux_f) at_aux_f(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iraxis_cc) raxis_cc(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == izaxis_cs) zaxis_cs(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == iraxis_cs) raxis_cs(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == izaxis_cc) zaxis_cc(arr_dex(nvar_in,1)) = x(nvar_in)
         IF (var_dex(nvar_in) == ibound_rbc) rbc(arr_dex(nvar_in,1),arr_dex(nvar_in,2)) = x(nvar_in)
         IF (var_dex(nvar_in) == ibound_rbs) rbs(arr_dex(nvar_in,1),arr_dex(nvar_in,2)) = x(nvar_in)
         IF (var_dex(nvar_in) == ibound_zbc) zbc(arr_dex(nvar_in,1),arr_dex(nvar_in,2)) = x(nvar_in)
         IF (var_dex(nvar_in) == ibound_zbs) zbs(arr_dex(nvar_in,1),arr_dex(nvar_in,2)) = x(nvar_in)
         IF (var_dex(nvar_in) == irhobc)     rhobc(arr_dex(nvar_in,1),arr_dex(nvar_in,2)) = x(nvar_in)
         IF (var_dex(nvar_in) == ideltamn)   deltamn(arr_dex(nvar_in,1),arr_dex(nvar_in,2)) = x(nvar_in)
         IF (var_dex(nvar_in) == icoil_splinefx)   coil_splinefx(arr_dex(nvar_in,1),arr_dex(nvar_in,2)) = x(nvar_in)
         IF (var_dex(nvar_in) == icoil_splinefy)   coil_splinefy(arr_dex(nvar_in,1),arr_dex(nvar_in,2)) = x(nvar_in)
         IF (var_dex(nvar_in) == icoil_splinefz)   coil_splinefz(arr_dex(nvar_in,1),arr_dex(nvar_in,2)) = x(nvar_in)
      END DO
      ! Adust Boundary Representation
      IF (ANY(var_dex == irhobc)) THEN
         CALL unique_boundary(rbc,zbs,rhobc,mpol1d,ntord,mpol-1,ntor,mpol-1,rho_exp)
      END IF
      IF (ANY(var_dex == ideltamn)) THEN
         CALL unique_boundary_PG(rbc,zbs,deltamn,ntord,mpol1d,mpol-1,ntor)
      END IF
      ! Apply normalization
      aphi = aphi * norm_aphi
      am   = am   * norm_am
      ac   = ac   * norm_ac
      ai   = ai   * norm_ai
      ne_opt = ne_opt * norm_ne
      zeff_opt = zeff_opt * norm_zeff
      te_opt = te_opt * norm_te
      ti_opt = ti_opt * norm_ti
      th_opt = th_opt * norm_th
      am_aux_f = am_aux_f * norm_am
      ac_aux_f = ac_aux_f * norm_ac
      ai_aux_f = ai_aux_f * norm_ai
      phi_aux_f = phi_aux_f * norm_phi
      ne_aux_f = ne_aux_f * norm_ne
      zeff_aux_f = zeff_aux_f * norm_zeff
      te_aux_f = te_aux_f * norm_te
      ti_aux_f = ti_aux_f * norm_ti
      th_aux_f = th_aux_f * norm_th
      ah_aux_f = ah_aux_f * norm_ah
      at_aux_f = at_aux_f * norm_at

      ! Handle cleanup
      IF (iflag < -2) THEN
         CALL stellopt_clean_up(ncnt,iflag)
         iflag = 0
         ! Now normalize arrays otherwise we'll be multiplying by normalizations on next iteration for non-varied quantities
         aphi = aphi / norm_aphi
         am   = am   / norm_am
         ac   = ac   / norm_ac
         ai   = ai   / norm_ai
         ne_opt = ne_opt / norm_ne
         zeff_opt = zeff_opt / norm_zeff
         te_opt = te_opt / norm_te
         ti_opt = ti_opt / norm_ti
         th_opt = th_opt / norm_th
         am_aux_f = am_aux_f / norm_am
         ac_aux_f = ac_aux_f / norm_ac
         ai_aux_f = ai_aux_f / norm_ai
         phi_aux_f = phi_aux_f / norm_phi
         ne_aux_f = ne_aux_f / norm_ne
         zeff_aux_f = zeff_aux_f / norm_zeff
         te_aux_f = te_aux_f / norm_te
         ti_aux_f = ti_aux_f / norm_ti
         th_aux_f = th_aux_f / norm_th
         ah_aux_f = ah_aux_f / norm_ah
         at_aux_f = at_aux_f / norm_at
         RETURN
      END IF

      ! Handle lscreen
      lscreen = .false.
      if (iflag < 0) lscreen=.true.
      istat = iflag
      !PRINT *,myid,iflag,iflag+myid,MOD(iflag+myid,4)
      ! Generate Random errors
!      IF (ncnt > n) THEN
!         IF (MOD(iflag+myid,4) < 1) THEN
!            fvec(1:m) = 10*SQRT(bigno/m)
!            iflag = 0
!            aphi = aphi / norm_aphi
!            am   = am   / norm_am
!            ac   = ac   / norm_ac
!            ai   = ai   / norm_ai
!            ne_opt = ne_opt / norm_ne
!            zeff_opt = zeff_opt / norm_zeff
!            te_opt = te_opt / norm_te
!            ti_opt = ti_opt / norm_ti
!            th_opt = th_opt / norm_th
!            am_aux_f = am_aux_f / norm_am
!            ac_aux_f = ac_aux_f / norm_ac
!            ai_aux_f = ai_aux_f / norm_ai
!            phi_aux_f = phi_aux_f / norm_phi
!            ne_aux_f = ne_aux_f / norm_ne
!            zeff_aux_f = zeff_aux_f / norm_zeff
!            te_aux_f = te_aux_f / norm_te
!            ti_aux_f = ti_aux_f / norm_ti
!            th_aux_f = th_aux_f / norm_th
!            RETURN
!         END IF
!      END IF

      ! Handle making a temporary string
      IF (iflag .eq. -1) istat = 0
      WRITE(temp_str,'(i5)') istat
      proc_string = TRIM(TRIM(id_string) // '_opt' // TRIM(ADJUSTL(temp_str)))

      ! Handle coil geometry variations
      IF (lcoil_geom) THEN
         CALL stellopt_spline_to_coil(lscreen)
         ctemp_str = 'write_mgrid'
         CALL stellopt_paraexe(ctemp_str,proc_string,lscreen)
      END IF

      IF (iflag .eq. -1) THEN 
         IF (lverb) WRITE(6,*) '---------------------------  EQUILIBRIUM CALCULATION  ------------------------'
      END IF

      ! Assume we've already read the stellopt input namelist and any input files.
      CALL tolower(equil_type)
         SELECT CASE (TRIM(equil_type))
            CASE('vmec2000_old','animec','flow','satire')
               ! Handle ne ti te th
               ier=0
               CALL stellopt_prof_to_vmec(proc_string,ier)
               CALL stellopt_reinit_vmec
               ! This will flush all changes
               iunit = 37; iflag = 0
               CALL safe_open(iunit,iflag,TRIM('temp_input.'//TRIM(proc_string)),'unknown','formatted')
               CALL write_indata_namelist(iunit,ier)
               CALL FLUSH(iunit)
               ier=0
               ! Setup VMEC control array
               reset_string='wout_reset_file.nc'
               IF (lno_restart .or. (lscreen .and. .not.lrestart)) THEN
                  vctrl_array(4) = -1 ! Iterative evaluation
                  reset_string = ''
               ELSE
                  vctrl_array(4) = MAXLOC(ns_array,DIM=1)
               END IF
               IF (lscreen .and. .not.lrestart) proc_string = 'reset_file'  ! First run make the restart file
               vctrl_array(1) = restart_flag+timestep_flag+output_flag+reset_jacdt_flag ! Need restart to get profile variations
               vctrl_array(2) = 0     ! vmec error flag  
               vctrl_array(3) = -1    ! Use multigrid
               vctrl_array(5) = myid ! Output file sequence number
               !IF (TRIM(equil_type)=='animec') vctrl_array(1) = vctrl_array(1) + animec_flag
               !IF (TRIM(equil_type)=='flow' .or. TRIM(equil_type)=='satire') vctrl_array(1) = vctrl_array(1) + flow_flag
               DO pass = 1, 2
                  CALL runvmec(vctrl_array,proc_string,lscreen,MPI_COMM_SELF,reset_string)
                  ier=0; ier=vctrl_array(2); iflag = ier
                  IF (  ier == successful_term_flag  .or. &
                        ier == norm_term_flag) THEN
                     iflag = 0
                     CLOSE(UNIT=iunit,STATUS='delete')
                     EXIT
                  ELSE IF (.not. lno_restart .and. pass == 1) THEN ! Try recalcing from the beginning
                     CALL stellopt_prof_to_vmec(proc_string,ier)
                     vctrl_array(1) = restart_flag+timestep_flag+output_flag+reset_jacdt_flag
                     vctrl_array(2) = 0     ! vmec error flag  
                     vctrl_array(3) = -1    ! Use multigrid
                     vctrl_array(4) = 0
                     vctrl_array(5) = myid ! Output file sequence number
                     !IF (TRIM(equil_type)=='animec') vctrl_array(1) = vctrl_array(1) + animec_flag
                     !IF (TRIM(equil_type)=='flow' .or. TRIM(equil_type)=='satire') vctrl_array(1) = vctrl_array(1) + flow_flag
                  ELSE
                     CLOSE(UNIT=iunit)
                     iflag = -1
                     EXIT
                  END IF
               END DO
               IF (lscreen .and. lverb) WRITE(6,*)  '---------------------------  VMEC CALCULATION DONE  -------------------------'
            CASE('paravmec','parvmec','vmec2000')
               iflag = 0
               CALL stellopt_paraexe('paravmec_run',proc_string,lscreen)
               iflag = ier_paraexe
               IF (lscreen .and. lverb) WRITE(6,*)  '-------------------------  PARAVMEC CALCULATION DONE  -----------------------'
            CASE('vboot')
               iflag = 0
               CALL stellopt_vboot(lscreen,iflag)
            CASE('spec')
         END SELECT
         ! Check profiles for negative values of pressure
         dex = MINLOC(am_aux_s(2:),DIM=1)
         IF (dex > 2) THEN
            IF (ANY(am_aux_f(1:dex) < 0)) iflag = -55
            IF (ALL(am_aux_f(1:dex) == 0)) iflag = -55
         END IF
         IF (pres_scale < 0) iflag = -55
         ! Now call any functions necessary to read or load the
         ! equilibrium output.  Things like conversion to other
         ! coordinate systems should be put here.  Note that it should be
         ! a function call which is handles every equil_type.  Note these
         ! functions should handle iflag by returning immediately if
         ! iflag is set to a negative number upon entry.
         CALL stellopt_load_equil(lscreen,iflag)

         ! Calls to secondary codes
         proc_string_old = proc_string ! So we can find the DIAGNO files
         !IF (ANY(lbooz)) CALL stellopt_toboozer(lscreen,iflag)
         ctemp_str = 'booz_xform'
         IF (ANY(lbooz) .and. (iflag>=0)) CALL stellopt_paraexe(ctemp_str,proc_string,lscreen); iflag = ier_paraexe
         !IF (ANY(sigma_bootstrap < bigno)) CALL stellopt_bootsj(lscreen,iflag)
         ctemp_str = 'bootsj'
         IF (ANY(sigma_bootstrap < bigno) .and. (iflag>=0)) CALL stellopt_paraexe(ctemp_str,proc_string,lscreen); iflag = ier_paraexe
         IF (ANY(sigma_balloon < bigno)) CALL stellopt_balloon(lscreen,iflag)
         IF (lneed_magdiag) CALL stellopt_magdiag(lscreen,iflag)
         IF (ANY(sigma_neo < bigno)) CALL stellopt_neo(lscreen,iflag)
!DEC$ IF DEFINED (TERPSICHORE)
         !IF (ANY(sigma_kink < bigno)) CALL stellopt_kink(lscreen,iflag)
         ctemp_str = 'terpsichore'
         IF (ANY(sigma_kink < bigno) .and. (iflag>=0)) CALL stellopt_paraexe(ctemp_str,proc_string,lscreen)
!DEC$ ENDIF
!DEC$ IF DEFINED (TRAVIS)
         IF (ANY(sigma_ece < bigno)) CALL stellopt_travis(lscreen,iflag)
!DEC$ ENDIF
!DEC$ IF DEFINED (DKES_OPT)
         IF (ANY(sigma_dkes < bigno)) CALL stellopt_dkes(lscreen,iflag)
!DEC$ ENDIF

         ! NOTE ALL parallel secondary codes go here
!DEC$ IF DEFINED (TXPORT_OPT)
         IF (ANY(sigma_txport < bigno)) CALL stellopt_txport(lscreen,iflag)
!DEC$ ENDIF
!DEC$ IF DEFINED (BEAMS3D_OPT)
         IF (ANY(sigma_orbit < bigno)) CALL stellopt_orbits(lscreen,iflag)
!DEC$ ENDIF
!DEC$ IF DEFINED (COILOPTPP)
         ctemp_str = 'coilopt++'
         IF (sigma_coil_bnorm < bigno .and. (iflag>=0)) CALL stellopt_paraexe(ctemp_str,proc_string,lscreen)
!DEC$ ENDIF

         ! Now we load target values if an error was found then
         ! exagerate the fvec values so that those directions are not
         ! searched this levenberg step
         IF (iflag == 0) THEN
            CALL stellopt_load_targets(m,fvec,iflag,ncnt)
            WHERE(ABS(fvec) > bigno) fvec = bigno
            ier_paraexe = 0
         ELSE
            IF (lscreen) RETURN ! Make sure we can do at least the initial integration
            fvec(1:m) = 10*SQRT(bigno/m)
            iflag = 0 ! Because we wish to continue
            ier_paraexe = 0
         END IF
      ! Now normalize arrays otherwise we'll be multiplying by normalizations on next iteration for non-varied quantities
      aphi = aphi / norm_aphi
      am   = am   / norm_am
      ac   = ac   / norm_ac
      ai   = ai   / norm_ai
      ne_opt = ne_opt / norm_ne
      zeff_opt = zeff_opt / norm_zeff
      te_opt = te_opt / norm_te
      ti_opt = ti_opt / norm_ti
      th_opt = th_opt / norm_th
      am_aux_f = am_aux_f / norm_am
      ac_aux_f = ac_aux_f / norm_ac
      ai_aux_f = ai_aux_f / norm_ai
      phi_aux_f = phi_aux_f / norm_phi
      ne_aux_f = ne_aux_f / norm_ne
      zeff_aux_f = zeff_aux_f / norm_zeff
      te_aux_f = te_aux_f / norm_te
      ti_aux_f = ti_aux_f / norm_ti
      th_aux_f = th_aux_f / norm_th
      ah_aux_f = ah_aux_f / norm_ah
      at_aux_f = at_aux_f / norm_at
      RETURN
!----------------------------------------------------------------------
!     END SUBROUTINE
!----------------------------------------------------------------------
      END SUBROUTINE stellopt_fcn