!-----------------------------------------------------------------------
!     Subroutine:    stellopt_spline_to_coil
!     Authors:       S. Lazerson (lazerson@pppl.gov)
!     Date:          11/14/2016
!     Description:   This subroutine the stellopt splines and generates
!                    a coil data structure from them.  It also writes
!                    the coil to a file.
!-----------------------------------------------------------------------
      SUBROUTINE stellopt_spline_to_coil(lscreen)
!-----------------------------------------------------------------------
!     Libraries
!-----------------------------------------------------------------------
      USE stel_kinds, ONLY: rprec
      USE vmec_input, ONLY: nfp, lasym, extcur
      USE stellopt_vars
      USE equil_utils, nfp_stel => nfp, lasym_stel=>lasym, extcur_stel=>extcur
      USE safe_open_mod
      USE EZspline_obj
      USE EZspline
      IMPLICIT NONE
!-----------------------------------------------------------------------
!     Subroutine Parameters
!----------------------------------------------------------------------
      LOGICAL, INTENT(inout)        :: lscreen
!-----------------------------------------------------------------------
!     Local Variables
!        ier         Error flag
!        iunit       File unit number
!----------------------------------------------------------------------
      LOGICAL ::  lmodular
      INTEGER ::  i, j, k, ier, nelx_coil, nely_coil,nelz_coil, n_coilgroups, &
                  iunit
      REAL(rprec) :: s_val, ph, rc_max, rc_min,zc_max,zc_min
      REAL(rprec), ALLOCATABLE :: x_coil(:),y_coil(:),z_coil(:),c_coil(:), &
                                  p_coil(:), r_coil(:)
      TYPE(EZspline1_r8) :: XC_spl, YC_spl, ZC_spl
      CHARACTER(LEN=8) :: coil_name

      INTEGER, PARAMETER :: nseg = 128
!----------------------------------------------------------------------
!     BEGIN SUBROUTINE
!----------------------------------------------------------------------
      IF (lscreen) WRITE(6,*) '---------------------------  WRITING COIL  ------------------------'
      ! Allocate coil helpers
      ALLOCATE(x_coil(nseg),y_coil(nseg),z_coil(nseg),c_coil(nseg))
      IF (.not. lasym) ALLOCATE(r_coil(nseg),p_coil(nseg))
      rc_max = 0; rc_min = 1000; zc_min = 100; zc_max = -100

      ! Count coil groups
      n_coilgroups = 0
      DO i = 1, nigroup
         IF (ANY(coil_splinesx(i,:) >-1)) n_coilgroups=n_coilgroups+1
      END DO

      ! Open files and print header
      CALL safe_open(iunit,ier,TRIM('coils.'//TRIM(proc_string)),'unknown','formatted')
      WRITE(iunit,'(A,I3)') 'periods',nfp
      WRITE(iunit,'(A)') 'begin filament'
      WRITE(iunit,'(A)') 'mirror NIL'
      CALL FLUSH(iunit)

      ! Print out some info
      IF (lscreen) THEN
          WRITE(6,'(2X,A,A)')  'COIL NAME: ',TRIM('coils.'//TRIM(proc_string))
          WRITE(6,'(2X,A,I2)') '      NFP: ',nfp
          WRITE(6,'(2X,A,I2)') '   GROUPS: ',n_coilgroups
          CALL FLUSH(6)
      END IF

      ! Write Coils
      DO i = 1, n_coilgroups
         ! Setup the Coil name
         WRITE(coil_name,'(A,I3.3)') 'COIL_',i
         ! Count Spline knots
         nelx_coil = COUNT(coil_splinesx(i,:)>=0)
         nely_coil = COUNT(coil_splinesy(i,:)>=0)
         nelz_coil = COUNT(coil_splinesz(i,:)>=0)
         ! Check modularity
         lmodular = .FALSE.
         IF ((coil_splinefx(i,1)==coil_splinefx(i,nelx_coil))&
             .and. (coil_splinefy(i,1)==coil_splinefy(i,nely_coil)) &
             .and.(coil_splinefz(i,1)==coil_splinefz(i,nelz_coil))) lmodular = .TRUE.
         ! Setup splines
         IF (EZspline_allocated(XC_spl)) CALL EZspline_free(XC_spl,ier)
         IF (EZspline_allocated(YC_spl)) CALL EZspline_free(YC_spl,ier)
         IF (EZspline_allocated(ZC_spl)) CALL EZspline_free(ZC_spl,ier)
         CALL EZspline_init(XC_spl,nelx_coil,bcs1,ier)
         CALL EZspline_init(YC_spl,nely_coil,bcs1,ier)
         CALL EZspline_init(ZC_spl,nelz_coil,bcs1,ier)
         XC_spl%x1 = coil_splinesx(i,1:nelx_coil)
         YC_spl%x1 = coil_splinesy(i,1:nely_coil)
         ZC_spl%x1 = coil_splinesz(i,1:nelz_coil)
         XC_spl%isHermite = 1
         YC_spl%isHermite = 1
         ZC_spl%isHermite = 1
         CALL EZspline_setup(XC_spl,coil_splinefx(i,1:nelx_coil),ier)
         CALL EZspline_setup(YC_spl,coil_splinefy(i,1:nely_coil),ier)
         CALL EZspline_setup(ZC_spl,coil_splinefz(i,1:nelz_coil),ier)
         ! Evaluate the coil
         DO j = 1, nseg
            s_val = REAL(j-1)/REAL(nseg-1)
            CALL EZspline_interp(XC_spl,s_val,x_coil(j),ier)
            CALL EZspline_interp(YC_spl,s_val,y_coil(j),ier)
            CALL EZspline_interp(ZC_spl,s_val,z_coil(j),ier)
         END DO
         c_coil(1:nseg) = extcur(i)
         IF (extcur(i) == 0) c_coil = 1
         ! Write Coil
         IF (lmodular) THEN ! Coil closes in a field period
            ! Screen output
            IF (lscreen) WRITE(6,'(5X,A,2X,I3,2X,A)') coil_name,nelx_coil,'MODULAR'
            ! Setup the coil
            x_coil(nseg) = x_coil(1); y_coil(nseg)=y_coil(1); z_coil(nseg)=z_coil(1)
            r_coil = sqrt(x_coil*x_coil + y_coil*y_coil)
            p_coil = atan2(y_coil,x_coil)
            ! Update Helpers
            rc_max = MAX(rc_max,MAXVAL(r_coil))
            rc_min = MIN(rc_min,MINVAL(r_coil))
            zc_max = MAX(zc_max,MAXVAL(z_coil))
            zc_min = MIN(zc_min,MINVAL(z_coil))
            ! Write the coil each field period
            DO k = 1, nfp
               ph = pi2*(k-1)/nfp
               DO j = 1, nseg-1
                  WRITE(iunit,'(4ES20.12)') r_coil(j)*cos(p_coil(j)+ph),&
                                            r_coil(j)*sin(p_coil(j)+ph),&
                                            z_coil(j),c_coil(j)
               END DO
               WRITE(iunit,'(4ES20.12,I5,1X,A)') r_coil(1)*cos(p_coil(1)+ph),&
                                                 r_coil(1)*sin(p_coil(1)+ph),&
                                                 z_coil(1),0.,i,coil_name
            END DO
            CALL FLUSH(6)
            ! Handle stellarator symmetry
            IF (.not. lasym) THEN
               ! Screen output
               ! Mirror Coil
               p_coil = pi2/nfp - p_coil
               z_coil = -z_coil
               DO k = 1, nfp
                  ph = pi2*(k-1)/nfp
                  DO j = nseg,2,-1
                     WRITE(iunit,'(4ES20.12)') r_coil(j)*cos(p_coil(j)+ph),&
                                               r_coil(j)*sin(p_coil(j)+ph),&
                                               z_coil(j),c_coil(j)
                  END DO
                  WRITE(iunit,'(4ES20.12,I5,1X,A)') r_coil(nseg)*cos(p_coil(nseg)+ph),&
                                                    r_coil(nseg)*sin(p_coil(nseg)+ph),&
                                                    z_coil(nseg),0.,i,coil_name
               END DO
            END IF
         ELSE ! Coil is toroidal segment
            IF (lscreen) WRITE(6,'(5X,A,2X,I3,2X,A)') coil_name,nelx_coil,'REGULAR'
            r_coil = sqrt(x_coil*x_coil + y_coil*y_coil)
            p_coil = atan2(y_coil,x_coil)
            ! Update Helpers
            rc_max = MAX(rc_max,MAXVAL(r_coil))
            rc_min = MIN(rc_min,MINVAL(r_coil))
            zc_max = MAX(zc_max,MAXVAL(z_coil))
            zc_min = MIN(zc_min,MINVAL(z_coil))
            DO k = 1, nfp
               ph = pi2*(k-1)/nfp
               DO j = 1, nseg-1
                  WRITE(iunit,'(4ES20.12)') r_coil(j)*cos(p_coil(j)+ph),&
                                            r_coil(j)*sin(p_coil(j)+ph),&
                                            z_coil(j),c_coil(j)
               END DO
            END DO
            WRITE(iunit,'(4ES20.12,I5,1X,A)') r_coil(1)*cos(p_coil(1)),&
                                              r_coil(1)*sin(p_coil(1)),&
                                              z_coil(1),0.,i,coil_name
         END IF
      END DO
      WRITE(iunit,'(A)') 'end'

      ! Close file
      CLOSE(iunit)

      ! General Info
      IF (lscreen) THEN
          WRITE(6,'(A,F8.5,A,F8.5,A)') '   R   = [',rc_min,',',rc_max,']'
          WRITE(6,'(A,F8.5,A,F8.5,A)') '   Z   = [',zc_min,',',zc_max,']'
          CALL FLUSH(6)
      END IF

      ! Clean up
      DEALLOCATE(x_coil,y_coil,z_coil,c_coil)
      IF (ALLOCATED(r_coil)) DEALLOCATE(r_coil)
      IF (ALLOCATED(p_coil)) DEALLOCATE(p_coil)

      RETURN
!----------------------------------------------------------------------
!     END SUBROUTINE
!----------------------------------------------------------------------
      END SUBROUTINE stellopt_spline_to_coil