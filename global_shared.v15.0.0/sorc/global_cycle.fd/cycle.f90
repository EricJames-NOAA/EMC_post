 PROGRAM SFC_DRV

!----------------------------------------------------------------------
!
!  Stand alone surface cycle driver for the cubed-sphere grid.
!
!  2005-02-03:  Iredell   for global_analysis
!  2014-11-30:  xuli      add nst_anl
!  2015-05-26:  Hang Lei  Added NEMSIO read/write function in the code
!  2017-08-08:  Gayno     Modify to work on cubed-sphere grid
!
!  LUGB         Unit number used in the sfccycle subprogram
!  IDIM,JDIM    i/j dimension of a cubed-sphere tile.
!  IY,IM,ID,IH  Year, month, day, and hour of initial state.
!  FH           Forecast hour
!  IALB         Use modis albedo when '1'. Use brigleb when '0'.
!  ISOT         Use statsgo soil type when '1'. Use zobler when '0'.
!  IVEGSRC      Use igbp veg type when '1'.  Use sib when '2'.
!  SIG1T        Sigma level 1 temperature for dead start.
!               If not dead start, no need for dimension but set to
!               zero as in the example below.
!----------------------------------------------------------------------

 IMPLICIT NONE
!
 INTEGER :: IDIM, JDIM, LSOIL, LUGB, IY, IM, ID, IH, IALB
 INTEGER :: ISOT, IVEGSRC, LENSFC
 REAL    :: FH, DELTSFC, ZSEA1, ZSEA2
 LOGICAL :: USE_UFO, NST_ANL
!
 NAMELIST/NAMCYC/ IDIM,JDIM,LSOIL,LUGB,IY,IM,ID,IH,FH,    &
                  DELTSFC,IALB,USE_UFO,NST_ANL,           &
                  ISOT,IVEGSRC,ZSEA1,ZSEA2
!
 DATA IDIM,JDIM,LSOIL/96,96,4/
 DATA IY,IM,ID,IH,FH/1997,8,2,0,0./
 DATA LUGB/51/, DELTSFC/0.0/, IALB/1/
 DATA ISOT/1/, IVEGSRC/2/, ZSEA1/0.0/, ZSEA2/0.0/
!
 PRINT*,"STARTING CYCLE PROGRAM."

 USE_UFO = .FALSE.
 NST_ANL = .FALSE.

 PRINT*,"READ NAMCYC NAMELIST."

 READ(5,NAMCYC)
 WRITE(6,NAMCYC)

 LENSFC = IDIM*JDIM ! TOTAL NUMBER OF POINTS FOR THE CUBED-SPHERE TILE

 PRINT*,"LUGB,IDIM,JDIM,LSOIL,DELTSFC,IY,IM,ID,IH,FH: ", &
              LUGB,IDIM,JDIM,LSOIL,DELTSFC,IY,IM,ID,IH,FH

 CALL SFCDRV(LUGB,IDIM,JDIM,LENSFC,LSOIL,DELTSFC,  &
             IY,IM,ID,IH,FH,IALB,                  &
             USE_UFO,NST_ANL,ZSEA1,ZSEA2,ISOT,IVEGSRC)
!
 PRINT*,'CYCLE PROGRAM COMPLETED NORMALLY.'

 STOP

 END PROGRAM SFC_DRV
!
 SUBROUTINE SFCDRV(LUGB,IDIM,JDIM,LENSFC,LSOIL,DELTSFC,  &
                   IY,IM,ID,IH,FH,IALB,                  &
                   USE_UFO,NST_ANL,ZSEA1,ZSEA2,ISOT,IVEGSRC)
!
 USE READ_WRITE_DATA

 IMPLICIT NONE

 INTEGER, INTENT(IN) :: IDIM, JDIM, LENSFC, LSOIL, IALB
 INTEGER, INTENT(IN) :: LUGB, IY, IM, ID, IH
 INTEGER, INTENT(IN) :: ISOT, IVEGSRC

 LOGICAL, INTENT(IN) :: USE_UFO, NST_ANL
 
 REAL, INTENT(IN)    :: FH, DELTSFC, ZSEA1, ZSEA2

 INTEGER, PARAMETER  :: NLUNIT=35, ME=0

 CHARACTER*500       :: FNOROG, FNGRID, FNBGSI, FNBGSO, GSI_FILE

 INTEGER             :: IFP, I

 REAL                :: SLMASK(LENSFC), OROG(LENSFC)
 REAL                :: SIHFCS(LENSFC), SICFCS(LENSFC)
 REAL                :: SITFCS(LENSFC), TSFFCS(LENSFC)
 REAL                :: SNOFCS(LENSFC), ZORFCS(LENSFC)
 REAL                :: ALBFCS(LENSFC,4), TG3FCS(LENSFC)
 REAL                :: CNPFCS(LENSFC), SMCFCS(LENSFC,LSOIL)
 REAL                :: STCFCS(LENSFC,LSOIL), SLIFCS(LENSFC)
 REAL                :: AISFCS(LENSFC), F10M(LENSFC)
 REAL                :: VEGFCS(LENSFC), VETFCS(LENSFC)
 REAL                :: SOTFCS(LENSFC), ALFFCS(LENSFC,2)
 REAL                :: CVFCS(LENSFC), CVTFCS(LENSFC)
 REAL                :: CVBFCS(LENSFC), TPRCP(LENSFC)
 REAL                :: SRFLAG(LENSFC), SWDFCS(LENSFC)
 REAL                :: SLCFCS(LENSFC,LSOIL), VMXFCS(LENSFC)
 REAL                :: VMNFCS(LENSFC), T2M(LENSFC)
 REAL                :: Q2M(LENSFC), SLPFCS(LENSFC)
 REAL                :: ABSFCS(LENSFC), OROG_UF(LENSFC)
 REAL                :: USTAR(LENSFC)
 REAL                :: FMM(LENSFC), FHH(LENSFC)
 REAL                :: RLA(LENSFC), RLO(LENSFC)
 REAL(KIND=4)        :: ZSOIL(LSOIL)
 REAL                :: SIG1T(LENSFC)
 REAL, ALLOCATABLE   :: SLIFCS_FG(:)

 TYPE(NSST_DATA)     :: NSST

!  Defaults file names
!
 DATA FNOROG/'        '/
 DATA FNGRID/'        '/
 DATA FNBGSI/'        '/
 DATA FNBGSO/'        '/
 DATA GSI_FILE/'        '/
!
 DATA IFP/0/
!
 SAVE IFP, FNGRID, FNOROG, FNBGSI, FNBGSO, GSI_FILE

 NAMELIST/NAMSFCD/FNOROG,FNGRID,FNBGSI,FNBGSO,GSI_FILE

!--------------------------------------------------------------------------------
!
!  THIS IS A DRIVER FOR VERSION II SURFACE PROGRAM.
!
!  This program runs in two different modes:
!
!  1.  Analysis mode (FH=0.)
!
!      This program merges climatology, analysis and forecast guess to create
!      new surface fields.  If analysis file is given, the program 
!      uses it if date of the analysis matches with IY,IM,ID,IH (see Note
!      below).
!
!  2.  Forecast mode (FH.GT.0.)
!    
!      This program interpolates climatology to the date corresponding to the 
!      forecast hour.  If surface analysis file is given, for the corresponding
!      dates, the program will use it.  This is forcing-by-observation experiment.
!
!   NOTE:
!
!      If the date of the analysis does not match given IY,IM,ID,IH, (and FH),
!      the program searches an old analysis by going back 6 hours, then 12 hours,
!      then one day upto NREPMX days (parameter statement in the SUBROTINE FIXRD. 
!      Now defined as 15).  This allows the user to provide non-daily analysis to 
!      be used.  If matching field is not found, the forecast guess will be used.
!
!      Use of a combined earlier surface analyses and current analysis is 
!      NOT allowed (as was done in the old version for snow analysis in which
!      old snow analysis is used in combination with initial guess), except
!      for sea surface temperature.  For sst anolmaly interpolation, you need to
!      set LANOM=.TRUE. and must provide sst analysis at initial time.  
!
!      If you want to do complex merging of past and present surface field analysis,
!      YOU NEED TO CREATE a separate file that contains DAILY SURFACE FIELD.
!
!      LUGB is the unit number used in sfccycle subprogram
!      IDIM,JDIM is thegrid dimension in x and y direction, respectively of a tile
!                of the cubed-sphere grid.
!      LSOIL is the number of soil layers 
!      IY,IM,ID,IH is the Year, month, day, and hour of initial state.
!      FH is the forecast hour
!      SIG1T is the sigma level 1 temperature for dead start.  
!
!  Variable naming conventions:
!
!     OROG .. Orography
!     ALB  .. Snow-free albedo
!     SNO  .. Liquid-equivalent snow depth
!     ZOR  .. Surface roughness length
!     VET  .. Vegetation type
!     TSF  .. Surface skin temperature.  Sea surface temp. over ocean.
!     TG3  .. Deep soil temperature (at 500cm)
!     STC  .. Soil temperature (LSOIL layrs)
!     SMC  .. Total soil moisture (LSOIL layrs)
!     AIS  .. Sea ice mask (0 or 1)
!     CNP  .. Canopy water content
!     CV   .. Convective cloud cover
!     CVB  .. Convective cloud base
!     CVT  .. Convective cloud top
!     SLI  .. LAND/SEA/SEA-ICE mask. (1/0/2 respectively)
!     VEG  .. Vegetation cover
!     SOT  .. Soil type
!     SIH  .. Sea ice thickness
!     SIC  .. Sea ice concentration
!     SWD  .. Actual snow depth
!     SLC  .. Liquid soil moisture (LSOIL layers)
!     VMN  .. Vegetation cover minimum
!     VMX  .. Vegetation cover maximum
!     SLP  .. Slope type
!     ABS  .. Maximum snow albedo
!     T2M  .. 2m Temperature
!     Q2M  .. 2m Specific Humidity
!     TICE .. Ice Temperature
!     OROG_UF .. Orography unfiltered
!
!  COEEFICIENTS OF BLENDING FORECAST AND INTERPOLATED CLIM
!  (OR ANALYZED) FIELDS OVER SEA OR LAND(L) (NOT FOR CLOUDS)
!  1.0 = USE OF FORECAST
!  0.0 = REPLACE WITH INTERPOLATED ANALYSIS
!
!   These values are set for analysis mode.
!
!   Variables                  Land                 Sea
!   ---------------------------------------------------------
!   Surface temperature        Forecast             Analysis
!   Albedo                     Analysis             Analysis
!   Sea-ice                    Analysis             Analysis
!   Snow                       Analysis             Forecast (over sea ice)
!   Roughness                  Analysis             Forecast
!   Plant resistance           Analysis             Analysis
!   Soil wetness (layer)       Weighted average     Analysis
!   Soil temperature           Forecast             Analysis
!   Canopy waver content       Forecast             Forecast
!   Convective cloud cover     Forecast             Forecast
!   Convective cloud bottm     Forecast             Forecast
!   Convective cloud top       Forecast             Forecast
!   Vegetation cover           Analysis             Analysis
!   vegetation type            Analysis             Analysis
!   soil type                  Analysis             Analysis
!
!--------------------------------------------------------------------------------

 SIG1T = 0.0            ! Not a dead start!

 IF(IFP.EQ.0) THEN
   IFP = 1
   READ (5,NAMSFCD)
   WRITE(6,NAMSFCD)
 ENDIF

 PRINT*,'IN ROUTINE SFCDRV,IDIM=',IDIM,'JDIM=',JDIM,'FH=',FH

!--------------------------------------------------------------------------------
! READ THE OROGRAPHY AND GRID POINT LAT/LONS FOR THE CUBED-SPHERE TILE.
!--------------------------------------------------------------------------------

 CALL READ_LAT_LON_OROG(RLA,RLO,OROG,OROG_UF,FNOROG,FNGRID,  &
                        IDIM,JDIM,LENSFC)

 IF (NST_ANL) THEN
   PRINT*,"WILL PROCESS NSST RECORDS."
   ALLOCATE(NSST%C_0(LENSFC))
   ALLOCATE(NSST%C_D(LENSFC))
   ALLOCATE(NSST%D_CONV(LENSFC))
   ALLOCATE(NSST%DT_COOL(LENSFC))
   ALLOCATE(NSST%IFD(LENSFC))
   ALLOCATE(NSST%QRAIN(LENSFC))
   ALLOCATE(NSST%TREF(LENSFC))
   ALLOCATE(NSST%W_0(LENSFC))
   ALLOCATE(NSST%W_D(LENSFC))
   ALLOCATE(NSST%XS(LENSFC))
   ALLOCATE(NSST%XT(LENSFC))
   ALLOCATE(NSST%XTTS(LENSFC))
   ALLOCATE(NSST%XU(LENSFC))
   ALLOCATE(NSST%XV(LENSFC))
   ALLOCATE(NSST%XZ(LENSFC))
   ALLOCATE(NSST%XZTS(LENSFC))
   ALLOCATE(NSST%Z_C(LENSFC))
   ALLOCATE(NSST%ZM(LENSFC))
   ALLOCATE(SLIFCS_FG(LENSFC))
 ENDIF

!--------------------------------------------------------------------------------
! READ THE INPUT SURFACE DATA ON THE CUBED-SPHERE TILE.
!--------------------------------------------------------------------------------

 CALL READ_DATA(TSFFCS,SMCFCS,SNOFCS,STCFCS,TG3FCS,ZORFCS,  &
                CVFCS,CVBFCS,CVTFCS,ALBFCS,SLIFCS,          &
                VEGFCS,CNPFCS,F10M,VETFCS,SOTFCS,           &
                ALFFCS,USTAR,FMM,FHH,SIHFCS,SICFCS,         &
                SITFCS,TPRCP,SRFLAG,SWDFCS,VMNFCS,          &
                VMXFCS,SLCFCS,SLPFCS,ABSFCS,T2M,Q2M,        &
                SLMASK,ZSOIL,LSOIL,LENSFC,FNBGSI,NST_ANL,NSST)

 IF (USE_UFO) THEN
   PRINT*,'USE UNFILTERED OROGRAPHY.'
 ELSE
   OROG_UF = 0.0
 ENDIF
 
 DO I=1,LENSFC
   AISFCS(I) = 0.
   IF(NINT(SLIFCS(I)).EQ.2) AISFCS(I) = 1.
 ENDDO

 IF (NST_ANL) SLIFCS_FG = SLIFCS

!do i = 1, lensfc
!  if (nint(slifcs(i)) == 0 .and. nsst%tref(i) < 271.2) then
!    print*,'warning, backgnd tref below freez: ',i,nsst%tref(i)
!  endif
!enddo

!--------------------------------------------------------------------------------
! UPDATE SURFACE FIELDS.
!--------------------------------------------------------------------------------

 CALL SFCCYCLE(LUGB,LENSFC,LSOIL,SIG1T,DELTSFC,          &
               IY,IM,ID,IH,FH,RLA,RLO,                   &
               SLMASK,OROG, OROG_UF, USE_UFO, NST_ANL,   &
               SIHFCS,SICFCS,SITFCS,SWDFCS,SLCFCS,       &
               VMNFCS,VMXFCS,SLPFCS,ABSFCS,              &
               TSFFCS,SNOFCS,ZORFCS,ALBFCS,TG3FCS,       &
               CNPFCS,SMCFCS,STCFCS,SLIFCS,AISFCS,F10M,  &
               VEGFCS,VETFCS,SOTFCS,ALFFCS,              &
               CVFCS,CVBFCS,CVTFCS,ME,NLUNIT,IALB,ISOT,IVEGSRC)

!--------------------------------------------------------------------------------
! IF RUNNING WITH NSST, READ IN GSI FILE WITH THE UPDATED INCREMENTS (ON THE
! GAUSSIAN GRID), INTERPOLATE INCREMENTS TO THE CUBED-SPHERE TILE, AND PERFORM
! REQUIRED ADJUSTMENTS AND QC.
!--------------------------------------------------------------------------------

 IF (NST_ANL) THEN
   CALL READ_GSI_DATA(GSI_FILE)
   CALL ADJUST_NSST(RLA,RLO,SLIFCS,SLIFCS_FG,TSFFCS,SITFCS,STCFCS, &
                    NSST,LENSFC,LSOIL,IDIM,ZSEA1,ZSEA2,IM,ID)
 ENDIF

!--------------------------------------------------------------------------------
! WRITE OUT UPDATED SURFACE DATA ON THE CUBED-SPHERE TILE.
!--------------------------------------------------------------------------------

 CALL WRITE_DATA(SLIFCS,TSFFCS,SNOFCS,TG3FCS,ZORFCS,         &
                 ALBFCS,ALFFCS,VEGFCS,CNPFCS,F10M,           &
                 T2M,Q2M,VETFCS,SOTFCS,USTAR,FMM,FHH,        &
                 SICFCS,SIHFCS,SITFCS,                       &
                 TPRCP,SRFLAG,SWDFCS,                        &
                 VMNFCS,VMXFCS,SLPFCS,ABSFCS,                &
                 SLCFCS,SMCFCS,STCFCS,                       &
                 IDIM,JDIM,LENSFC,LSOIL,FNBGSO,NST_ANL,NSST)

 IF (NST_ANL) THEN
   DEALLOCATE(NSST%C_0)
   DEALLOCATE(NSST%C_D)
   DEALLOCATE(NSST%D_CONV)
   DEALLOCATE(NSST%DT_COOL)
   DEALLOCATE(NSST%IFD)
   DEALLOCATE(NSST%QRAIN)
   DEALLOCATE(NSST%TREF)
   DEALLOCATE(NSST%W_0)
   DEALLOCATE(NSST%W_D)
   DEALLOCATE(NSST%XS)
   DEALLOCATE(NSST%XT)
   DEALLOCATE(NSST%XTTS)
   DEALLOCATE(NSST%XU)
   DEALLOCATE(NSST%XV)
   DEALLOCATE(NSST%XZ)
   DEALLOCATE(NSST%XZTS)
   DEALLOCATE(NSST%Z_C)
   DEALLOCATE(NSST%ZM)
   DEALLOCATE(SLIFCS_FG)
 ENDIF

 RETURN

 END SUBROUTINE SFCDRV
 
 SUBROUTINE ADJUST_NSST(RLA,RLO,SLMSK_TILE,SLMSK_FG_TILE,SKINT_TILE,&
                        SICET_TILE,SOILT_TILE,NSST,LENSFC,LSOIL,    &
                        IDIM,ZSEA1,ZSEA2,MON,DAY)

 USE GDSWZD_MOD
 USE READ_WRITE_DATA, ONLY : IDIM_GAUS, JDIM_GAUS, &
                             SLMSK_GAUS, DTREF_GAUS, &
                             NSST_DATA

 IMPLICIT NONE

 INTEGER, INTENT(IN)      :: LENSFC, LSOIL, IDIM, MON, DAY

 REAL, INTENT(IN)         :: SLMSK_TILE(LENSFC), SLMSK_FG_TILE(LENSFC)
 REAL, INTENT(IN)         :: ZSEA1, ZSEA2
 REAL, INTENT(INOUT)      :: RLA(LENSFC), RLO(LENSFC), SKINT_TILE(LENSFC)
 REAL, INTENT(INOUT)      :: SICET_TILE(LENSFC), SOILT_TILE(LENSFC,LSOIL)

 TYPE(NSST_DATA)          :: NSST

 REAL, PARAMETER          :: TFREEZ=271.21
 REAL, PARAMETER          :: TMAX=313.0

 INTEGER                  :: IOPT, NRET, KGDS_GAUS(200)
 INTEGER                  :: IGAUS, JGAUS, IJ, II, JJ, III, JJJ, KRAD
 INTEGER                  :: ISTART, IEND, JSTART, JEND
 INTEGER                  :: MASK_TILE, MASK_FG_TILE
 INTEGER                  :: ITILE, JTILE
 INTEGER                  :: MAX_SEARCH

 LOGICAL                  :: IS_ICE

 REAL                     :: FILL, DTZM, GAUS_RES_KM, DTREF
 REAL, ALLOCATABLE        :: XPTS(:), YPTS(:)

 KGDS_GAUS     = 0
 KGDS_GAUS(1)  = 4          ! OCT 6 - TYPE OF GRID (GAUSSIAN)
 KGDS_GAUS(2)  = IDIM_GAUS  ! OCT 7-8 - # PTS ON LATITUDE CIRCLE
 KGDS_GAUS(3)  = JDIM_GAUS
 KGDS_GAUS(4)  = 90000      ! OCT 11-13 - LAT OF ORIGIN
 KGDS_GAUS(5)  = 0          ! OCT 14-16 - LON OF ORIGIN
 KGDS_GAUS(6)  = 128        ! OCT 17 - RESOLUTION FLAG
 KGDS_GAUS(7)  = -90000     ! OCT 18-20 - LAT OF EXTREME POINT
 KGDS_GAUS(8)  = NINT(-360000./FLOAT(IDIM_GAUS))  ! OCT 21-23 - LON OF EXTREME POINT
 KGDS_GAUS(9)  = NINT((360.0 / FLOAT(IDIM_GAUS))*1000.0)
                            ! OCT 24-25 - LONGITUDE DIRECTION INCR.
 KGDS_GAUS(10) = JDIM_GAUS/2     ! OCT 26-27 - NUMBER OF CIRCLES POLE TO EQUATOR
 KGDS_GAUS(12) = 255        ! OCT 29 - RESERVED
 KGDS_GAUS(20) = 255        ! OCT 5  - NOT USED, SET TO 255

 PRINT*,'ADJUST NSST USING GSI INCREMENTS ON GAUSSIAN GRID'

!----------------------------------------------------------------------
! CALL TO GDSWZD DETERMINES THE NEAREST GSI/GAUSSIAN POINT TO EACH
! CUBED-SPHERE TILE POINT.
!----------------------------------------------------------------------

 IOPT = -1
 FILL = -9999.
 ALLOCATE(XPTS(LENSFC))
 ALLOCATE(YPTS(LENSFC))
 XPTS = FILL
 YPTS = FILL

 CALL GDSWZD(KGDS_GAUS,IOPT,LENSFC,FILL,XPTS,YPTS,RLO,RLA,NRET)

 IF (NRET /= LENSFC) THEN
   PRINT*,'PROBLEM IN GDSWZD'
   STOP 12
 ENDIF

!----------------------------------------------------------------------
! THE MAXIMUM DISTANCE TO SEARCH IS 500 KM. HOW MANY GAUSSIAN
! GRID LENGTHS IS THAT?
!----------------------------------------------------------------------

 GAUS_RES_KM = 360.0 / IDIM_GAUS * 111.0
 MAX_SEARCH  = CEILING(500.0/GAUS_RES_KM)

 print*,'MAXIMUM SEARCH IS ',MAX_SEARCH, ' GAUSSIAN POINTS.'

 IJ_LOOP : DO IJ = 1, LENSFC

   MASK_TILE    = NINT(SLMSK_TILE(IJ))
   MASK_FG_TILE = NINT(SLMSK_FG_TILE(IJ))

!----------------------------------------------------------------------
! THESE ARE ICE POINTS.  SET TREF TO FREEZING.
!----------------------------------------------------------------------

   IF (MASK_TILE == 2) THEN
     NSST%TREF(IJ) = TFREEZ
     CYCLE IJ_LOOP
   ENDIF

!----------------------------------------------------------------------
! IF THE MODEL POINT WAS ICE COVERED, BUT IS NOW OPEN WATER, SET
! TREF TO FREEZING, XZ TO '30' AND ALL OTHER FIELDS TO ZERO.
!----------------------------------------------------------------------

   IF (MASK_FG_TILE == 2 .AND. MASK_TILE == 0) THEN
     CALL NSST_WATER_RESET(NSST,IJ,TFREEZ)
     CYCLE IJ_LOOP
   ENDIF

!----------------------------------------------------------------------
! SKIP LAND POINTS.  NSST NOT APPLIED AT LAND.
!----------------------------------------------------------------------

   IF (MASK_TILE == 1) THEN
     CYCLE IJ_LOOP  
   ENDIF

!----------------------------------------------------------------------
! THESE ARE POINTS THAT ARE OPEN WATER AND WERE OPEN WATER PRIOR
! TO ANY ICE UPDATE BY SFCCYCLE.
!
! SEARCH FOR THE NEAREST GAUSSIAN OPEN WATER POINT.
!
! AT OPEN WATER POINTS, THE SEA ICE TEMPERATURE (SICET_TILE) AND
! SOIL COLUMN TEMPERATURE (SOILT_TILE) ARE SET TO THE SKIN TEMP.
! IT IS SIMPLY A FILLER VALUE.  THESE FIELDS ARE NOT USED AT
! OPEN WATER POINTS.
!----------------------------------------------------------------------

   JTILE = (IJ-1) / IDIM + 1
   ITILE = MOD(IJ,IDIM)
   IF (ITILE==0) ITILE = IDIM

   IGAUS = NINT(XPTS(IJ))
   IF (IGAUS > IDIM_GAUS) IGAUS = IGAUS - IDIM_GAUS
   IF (IGAUS < 1)         IGAUS = IDIM_GAUS + IGAUS
   JGAUS = NINT(YPTS(IJ))
   IF (JGAUS > JDIM_GAUS) JGAUS = JDIM_GAUS
   IF (JGAUS < 1)         JGAUS = 1

!----------------------------------------------------------------------
! AT THIS POINT, THE TILE POINT SHOULD BE OPEN WATER ("0").  SEE
! IF THE NEAREST GSI POINT MASK IS ALSO OPEN WATER.  IF SO, APPLY 
! NSST INCREMENT.
!----------------------------------------------------------------------

   IF (SLMSK_GAUS(IGAUS,JGAUS) == 0) THEN

     NSST%TREF(IJ) = NSST%TREF(IJ) + DTREF_GAUS(IGAUS,JGAUS)
     NSST%TREF(IJ) = MAX(NSST%TREF(IJ), TFREEZ)
     NSST%TREF(IJ) = MIN(NSST%TREF(IJ), TMAX)

     CALL DTZM_POINT(NSST%XT(IJ),NSST%XZ(IJ),NSST%DT_COOL(IJ),  &
                     NSST%Z_C(IJ),ZSEA1,ZSEA2,DTZM)

     SKINT_TILE(IJ) = NSST%TREF(IJ) + DTZM
     SKINT_TILE(IJ) = MAX(SKINT_TILE(IJ), TFREEZ)
     SKINT_TILE(IJ) = MIN(SKINT_TILE(IJ), TMAX)

     SICET_TILE(IJ)   = SKINT_TILE(IJ)
     SOILT_TILE(IJ,:) = SKINT_TILE(IJ)

!----------------------------------------------------------------------
! IF MASK IS NOT THE SAME, PERFORM A SPIRAL SEARCH TO FIND NEAREST 
! NON-LAND POINT ON GSI/GAUSSIAN GRID.
!----------------------------------------------------------------------

   ELSE  

     IS_ICE = .FALSE.

     DO KRAD = 1, MAX_SEARCH

       ISTART = IGAUS - KRAD
       IEND   = IGAUS + KRAD
       JSTART = JGAUS - KRAD
       JEND   = JGAUS + KRAD

       DO JJ = JSTART, JEND
       DO II = ISTART, IEND

         IF((JJ == JSTART) .OR. (JJ == JEND) .OR.   &
            (II == ISTART) .OR. (II == IEND))  THEN

           IF ((JJ >= 1) .AND. (JJ <= JDIM_GAUS)) THEN

             JJJ = JJ
             IF (II <= 0) THEN
               III = IDIM_GAUS + II
             ELSE IF (II >= (IDIM_GAUS+1)) THEN
               III = II - IDIM_GAUS
             ELSE
               III = II
             END IF

!----------------------------------------------------------------------
! SEE IF NEARBY POINTS ARE SEA ICE.  IF THEY ARE, AND THE SEARCH FOR
! A GAUSSIAN GRID OPEN WATER POINT FAILS, THEN TREF WILL BE SET TO
! FREEZING BELOW.
!----------------------------------------------------------------------

             IF (KRAD <= 2 .AND. SLMSK_GAUS(III,JJJ) == 2) IS_ICE = .TRUE.

             IF (SLMSK_GAUS(III,JJJ) == 0) THEN

               print*,'MISMATCH AT TILE POINT  ',itile,jtile
               print*,'UPDATE TREF USING GSI INCREMENT AT ',iii,jjj,dtref_gaus(iii,jjj)

               NSST%TREF(IJ) = NSST%TREF(IJ) + DTREF_GAUS(III,JJJ)
               NSST%TREF(IJ) = MAX(NSST%TREF(IJ), TFREEZ)
               NSST%TREF(IJ) = MIN(NSST%TREF(IJ), TMAX)

               CALL DTZM_POINT(NSST%XT(IJ),NSST%XZ(IJ),NSST%DT_COOL(IJ),  &
                     NSST%Z_C(IJ),ZSEA1,ZSEA2,DTZM)

               SKINT_TILE(IJ) = NSST%TREF(IJ) + DTZM
               SKINT_TILE(IJ) = MAX(SKINT_TILE(IJ), TFREEZ)
               SKINT_TILE(IJ) = MIN(SKINT_TILE(IJ), TMAX)

               SICET_TILE(IJ)   = SKINT_TILE(IJ)
               SOILT_TILE(IJ,:) = SKINT_TILE(IJ)
               CYCLE IJ_LOOP

             ENDIF ! Gaussian mask is open water

           ENDIF

         ENDIF

       ENDDO
       ENDDO

     ENDDO ! KRAD LOOP

!----------------------------------------------------------------------
! THE SEARCH FAILED.  IF THERE IS NEARBY ICE, SET TREF TO FREEZING.
! ELSE UPDATE TREF BASED ON THE ANNUAL SST CYCLE.
!----------------------------------------------------------------------

     print*,'WARNING !!!!!! SEARCH FAILED AT TILE POINT ',itile,jtile

     IF (IS_ICE) THEN
       NSST%TREF(IJ) = TFREEZ
       print*,"NEARBY ICE.  SET TREF TO FREEZING"
     ELSE
       CALL CLIMO_TREND(RLA(IJ),MON,DAY,DTREF)
       NSST%TREF(IJ) = NSST%TREF(IJ) + DTREF
       NSST%TREF(IJ) = MAX(NSST%TREF(IJ), TFREEZ)
       NSST%TREF(IJ) = MIN(NSST%TREF(IJ), TMAX)
       print*,'UPDATE TREF FROM SST CLIMO ',dtref
     ENDIF

     CALL DTZM_POINT(NSST%XT(IJ),NSST%XZ(IJ),NSST%DT_COOL(IJ),  &
                     NSST%Z_C(IJ),ZSEA1,ZSEA2,DTZM)

     SKINT_TILE(IJ) = NSST%TREF(IJ) + DTZM
     SKINT_TILE(IJ) = MAX(SKINT_TILE(IJ), TFREEZ)
     SKINT_TILE(IJ) = MIN(SKINT_TILE(IJ), TMAX)

     SICET_TILE(IJ)   = SKINT_TILE(IJ)
     SOILT_TILE(IJ,:) = SKINT_TILE(IJ)

   ENDIF  ! IS NEAREST GAUSSIAN POINT OPEN WATER?

 ENDDO IJ_LOOP

 DEALLOCATE (XPTS, YPTS)

 END SUBROUTINE ADJUST_NSST

 SUBROUTINE CLIMO_TREND(LATITUDE, MON, DAY, DTREF)

! SST VALUES BASED ON RTG CLIMO FILE IN FIXED DIRECTORY.

 IMPLICIT NONE

 INTEGER, INTENT(IN)    :: MON, DAY

 REAL, INTENT(IN)       :: LATITUDE
 REAL, INTENT(OUT)      :: DTREF

 INTEGER                :: NUM_DAYS(12), MON2, MON1

 REAL, TARGET           :: SST_80_90(12)
 REAL, TARGET           :: SST_70_80(12)
 REAL, TARGET           :: SST_60_70(12)
 REAL, TARGET           :: SST_50_60(12)
 REAL, TARGET           :: SST_40_50(12)
 REAL, TARGET           :: SST_30_40(12)
 REAL, TARGET           :: SST_20_30(12)
 REAL, TARGET           :: SST_10_20(12)
 REAL, TARGET           :: SST_00_10(12)
 REAL, TARGET           :: SST_M10_00(12)
 REAL, TARGET           :: SST_M20_M10(12)
 REAL, TARGET           :: SST_M30_M20(12)
 REAL, TARGET           :: SST_M40_M30(12)
 REAL, TARGET           :: SST_M50_M40(12)
 REAL, TARGET           :: SST_M60_M50(12)
 REAL, TARGET           :: SST_M70_M60(12)
 REAL, TARGET           :: SST_M80_M70(12)
 REAL, TARGET           :: SST_M90_M80(12)

 REAL, POINTER          :: SST(:)

 DATA NUM_DAYS  /31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31/

 DATA SST_80_90 /271.466, 271.458, 271.448, 271.445, 271.519, 271.636, & 
                 272.023, 272.066, 272.001, 271.698, 271.510, 271.472/

 DATA SST_70_80 /272.149, 272.103, 272.095, 272.126, 272.360, 272.988, &
                 274.061, 274.868, 274.415, 273.201, 272.468, 272.268/

 DATA SST_60_70 /274.240, 274.019, 273.988, 274.185, 275.104, 276.875, &
                 279.005, 280.172, 279.396, 277.586, 275.818, 274.803/

 DATA SST_50_60 /277.277, 276.935, 277.021, 277.531, 279.100, 281.357, &
                 283.735, 285.171, 284.399, 282.328, 279.918, 278.199/

 DATA SST_40_50 /281.321, 280.721, 280.850, 281.820, 283.958, 286.588, &
                 289.195, 290.873, 290.014, 287.652, 284.898, 282.735/

 DATA SST_30_40 /289.189, 288.519, 288.687, 289.648, 291.547, 293.904, &
                 296.110, 297.319, 296.816, 295.225, 292.908, 290.743/

 DATA SST_20_30 /294.807, 294.348, 294.710, 295.714, 297.224, 298.703, &
                 299.682, 300.127, 300.099, 299.455, 297.953, 296.177/

 DATA SST_10_20 /298.878, 298.720, 299.033, 299.707, 300.431, 300.709, &
                 300.814, 300.976, 301.174, 301.145, 300.587, 299.694/

 DATA SST_00_10 /300.415, 300.548, 300.939, 301.365, 301.505, 301.141, &
                 300.779, 300.660, 300.818, 300.994, 300.941, 300.675/

 DATA SST_M10_00 /300.226, 300.558, 300.914, 301.047, 300.645, 299.870, &
                  299.114, 298.751, 298.875, 299.294, 299.721, 299.989/

 DATA SST_M20_M10 /299.547, 299.985, 300.056, 299.676, 298.841, 297.788, &
                   296.893, 296.491, 296.687, 297.355, 298.220, 298.964/

 DATA SST_M30_M20 /297.524, 298.073, 297.897, 297.088, 295.846, 294.520, &
                   293.525, 293.087, 293.217, 293.951, 295.047, 296.363/

 DATA SST_M40_M30 /293.054, 293.765, 293.468, 292.447, 291.128, 289.781, &
                   288.773, 288.239, 288.203, 288.794, 289.947, 291.553/

 DATA SST_M50_M40 /285.052, 285.599, 285.426, 284.681, 283.761, 282.826, &
                   282.138, 281.730, 281.659, 281.965, 282.768, 283.961/

 DATA SST_M60_M50 /277.818, 278.174, 277.991, 277.455, 276.824, 276.229, &
                   275.817, 275.585, 275.560, 275.687, 276.142, 276.968/

 DATA SST_M70_M60 /273.436, 273.793, 273.451, 272.813, 272.349, 272.048, &
                   271.901, 271.838, 271.845, 271.889, 272.080, 272.607/

 DATA SST_M80_M70 /271.579, 271.578, 271.471, 271.407, 271.392, 271.391, &
                   271.390, 271.391, 271.394, 271.401, 271.422, 271.486/

 DATA SST_M90_M80 /271.350, 271.350, 271.350, 271.350, 271.350, 271.350, &
                   271.350, 271.350, 271.350, 271.350, 271.350, 271.350/

 NULLIFY(SST)
 IF (LATITUDE > 80.0) THEN
   SST => SST_80_90
 ELSEIF (LATITUDE > 70.0) THEN
   SST => SST_70_80
 ELSEIF (LATITUDE > 60.0) THEN
   SST => SST_60_70
 ELSEIF (LATITUDE > 50.0) THEN
   SST => SST_50_60
 ELSEIF (LATITUDE > 40.0) THEN
   SST => SST_40_50
 ELSEIF (LATITUDE > 30.0) THEN
   SST => SST_30_40
 ELSEIF (LATITUDE > 20.0) THEN
   SST => SST_20_30
 ELSEIF (LATITUDE > 10.0) THEN
   SST => SST_10_20
 ELSEIF (LATITUDE > 0.0) THEN
   SST => SST_00_10
 ELSEIF (LATITUDE > -10.0) THEN
   SST => SST_M10_00
 ELSEIF (LATITUDE > -20.0) THEN
   SST => SST_M20_M10
 ELSEIF (LATITUDE > -30.0) THEN
   SST => SST_M30_M20
 ELSEIF (LATITUDE > -40.0) THEN
   SST => SST_M40_M30
 ELSEIF (LATITUDE > -50.0) THEN
   SST => SST_M50_M40
 ELSEIF (LATITUDE > -60.0) THEN
   SST => SST_M60_M50
 ELSEIF (LATITUDE > -70.0) THEN
   SST => SST_M70_M60
 ELSEIF (LATITUDE > -80.0) THEN
   SST => SST_M80_M70
 ELSE
   SST => SST_M90_M80
 END IF

 IF (DAY >= 15) THEN
   MON2 = MON+1
   IF(MON2 == 13) MON2 = 1
   MON1 = MON
   DTREF = (SST(MON2) - SST(MON1)) / NUM_DAYS(MON1)
 ELSE
   MON1 = MON - 1
   IF (MON1 == 0) MON1=12
   MON2 = MON
   DTREF = (SST(MON2) - SST(MON1)) / NUM_DAYS(MON1)
 ENDIF

 END SUBROUTINE CLIMO_TREND

 SUBROUTINE DTZM_POINT(XT,XZ,DT_COOL,ZC,Z1,Z2,DTZM)
! ===================================================================== !
!                                                                       !
!  description:  get dtzm = mean of dT(z) (z1 - z2) with NSST dT(z)     !
!                dT(z) = (1-z/xz)*dt_warm - (1-z/zc)*dt_cool            !
!                                                                       !
!  usage:                                                               !
!                                                                       !
!    call dtzm_point                                                    !
!                                                                       !
!       inputs:                                                         !
!          (xt,xz,dt_cool,zc,z1,z2,                                     !
!       outputs:                                                        !
!          dtzm)                                                        !
!                                                                       !
!  program history log:                                                 !
!                                                                       !
!         2015  -- xu li       createad original code                   !
!  inputs:                                                              !
!     xt      - real, heat content in dtl                            1  !
!     xz      - real, dtl thickness                                  1  !
!     dt_cool - real, sub-layer cooling amount                       1  !
!     zc      - sub-layer cooling thickness                          1  !
!     z1      - lower bound of depth of sea temperature              1  !
!     z2      - upper bound of depth of sea temperature              1  !
!  outputs:                                                             !
!     dtzm   - mean of dT(z)  (z1 to z2)                             1  !
!
  implicit none

  real, intent(in)  :: xt,xz,dt_cool,zc,z1,z2
  real, intent(out) :: dtzm

  real, parameter   :: zero = 0.0
  real, parameter   :: one  = 1.0
  real, parameter   :: half = 0.5
  real              :: dt_warm,dtw,dtc
!
! get the mean warming in the range of z=z1 to z=z2
!
  dtw = zero
  if ( xt > zero ) then
    dt_warm = (xt+xt)/xz      ! Tw(0)
    if ( z1 < z2) then
      if ( z2 < xz ) then
        dtw = dt_warm*(one-(z1+z2)/(xz+xz))
      elseif ( z1 < xz .and. z2 >= xz ) then
        dtw = half*(one-z1/xz)*dt_warm*(xz-z1)/(z2-z1)
      endif
    elseif ( z1 == z2 ) then
      if ( z1 < xz ) then
        dtw = dt_warm*(one-z1/xz)
      endif
    endif
  endif
!
! get the mean cooling in the range of z=z1 to z=z2
!
  dtc = zero
  if ( zc > zero ) then
    if ( z1 < z2) then
      if ( z2 < zc ) then
        dtc = dt_cool*(one-(z1+z2)/(zc+zc))
      elseif ( z1 < zc .and. z2 >= zc ) then
        dtc = half*(one-z1/zc)*dt_cool*(zc-z1)/(z2-z1)
      endif
    elseif ( z1 == z2 ) then
      if ( z1 < zc ) then
        dtc = dt_cool*(one-z1/zc)
      endif
    endif
  endif

!
! get the mean T departure from Tf in the range of z=z1 to z=z2
!
  dtzm = dtw - dtc

 END SUBROUTINE DTZM_POINT

 SUBROUTINE NSST_WATER_RESET(NSST,IJ,TFREEZ)

! IF THE FIRST GUESS WAS SEA ICE, BUT THE ANALYSIS IS OPEN WATER,
! RESET ALL NSST VARIABLES.

 USE READ_WRITE_DATA, ONLY : NSST_DATA

 IMPLICIT NONE

 INTEGER, INTENT(IN)  :: IJ

 REAL, INTENT(IN)     :: TFREEZ

 TYPE(NSST_DATA), INTENT(INOUT)      :: NSST

 NSST%C_0(IJ)     = 0.0
 NSST%C_D(IJ)     = 0.0
 NSST%D_CONV(IJ)  = 0.0
 NSST%DT_COOL(IJ) = 0.0
 NSST%IFD(IJ)     = 0.0
 NSST%QRAIN(IJ)   = 0.0
 NSST%TREF(IJ)    = TFREEZ
 NSST%W_0(IJ)     = 0.0
 NSST%W_D(IJ)     = 0.0
 NSST%XS(IJ)      = 0.0
 NSST%XT(IJ)      = 0.0
 NSST%XTTS(IJ)    = 0.0
 NSST%XU(IJ)      = 0.0
 NSST%XV(IJ)      = 0.0
 NSST%XZ(IJ)      = 30.0
 NSST%XZTS(IJ)    = 0.0
 NSST%Z_C(IJ)     = 0.0
 NSST%ZM(IJ)      = 0.0

 END SUBROUTINE NSST_WATER_RESET
