!> @file
!> @brief MPI_FIRST set up message passing info.
!>
!> This routine sets up message passing info.
!>
!> ### Program history log:
!> Date | Programmer | Comments
!> -----|------------|---------
!> 2000-01-06 | Jim Tuccillo | Initial
!> 2001-10-25 | H Chuang     | Modified to process hybrid model output
!> 2002-06-19 | Mike Baldwin | WRF version
!> 2022-11-08 | Kai Wang     | Replace aqfcmaq_on with aqf_on
!>
!> @author Jim Tuccillo IBM @date 2000-01-06
      SUBROUTINE DE_ALLOCATE

!
      use vrbls4d
      use vrbls3d
      use vrbls2d
      use soil
      use masks
      use params_mod
      use ctlblk_mod
      use upp_math, only: ddvdx, ddudy, uuavg
!- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
!
       implicit none
!
      include 'mpif.h'
!
!
!     deallocate arrays
!
!
!     FROM VRBLS3D
!
      deallocate(u)
      deallocate(v)
      deallocate(t)
! CHUANG ADD POTENTIAL TEMP BECAUSE WRF OUTPUT THETA
!      deallocate(th)   
      deallocate(q)
!      deallocate(w(im,jsta_2l:jend_2u,lp1))
      deallocate(uh)
      deallocate(vh)
      deallocate(wh)
      deallocate(pmid)
      deallocate(pmidv)
      deallocate(pint)
      deallocate(alpint)
      deallocate(zmid)
      deallocate(zint)
!      deallocate(rainw(im,jsta_2l:jend_2u,lm))
      deallocate(q2)
      deallocate(omga)
      deallocate(dpres)
      deallocate(T_ADJ)
      deallocate(ttnd)
      deallocate(rswtt)
      deallocate(rlwtt)
      deallocate(exch_h) 
      deallocate(train)
      deallocate(tcucn)
      deallocate(EL_PBL)
!     MP FIELD   
      deallocate(cwm)
      deallocate(F_ice)
      deallocate(F_rain)
      deallocate(F_RimeF)
      deallocate(QQW)
      deallocate(QRIMEF)
      deallocate(QQI)
      deallocate(QQR)
      deallocate(QQS)
      deallocate(QQG)
      deallocate(QQNW)
      deallocate(QQNI)
      deallocate(QQNR)
      deallocate(QQNWFA)
      deallocate(QQNIFA)
      deallocate(TAOD5503D)
      deallocate(AEXTC55)
      deallocate(EXTCOF55)
      deallocate(QC_BL)
      deallocate(CFR)
      deallocate(CFR_RAW)
      deallocate(DBZ)
      deallocate(DBZR)
      deallocate(DBZI)
      deallocate(DBZC)
      deallocate(mcvg)
      deallocate(NLICE)
! KRS: HWRF addition for thompson reflectivity
! or non-ferrier physics. wrf-derived
      deallocate(REFL_10CM)
!     Wm Lewis: added
      deallocate(NRAIN)
      deallocate(radius_cloud)
      deallocate(radius_ice)
      deallocate(radius_snow)
!GFS FIELD
      deallocate(o3)
      deallocate(o)
      deallocate(o2)
      deallocate(tcucns)
      if(allocated(cd10)) deallocate(cd10)
      if(allocated(ch10)) deallocate(ch10)
! Add GFS d3d fields
      if (d3d_on) then
        deallocate(vdifftt)
!       deallocate(tcucns)
        deallocate(vdiffmois)
        deallocate(dconvmois)
        deallocate(sconvmois)
        deallocate(nradtt)
        deallocate(o3vdiff)
        deallocate(o3prod)
        deallocate(o3tndy)
        deallocate(mwpv)
        deallocate(unknown)
        deallocate(vdiffzacce)
        deallocate(zgdrag)
        deallocate(cnvctummixing)
        deallocate(vdiffmacce)
        deallocate(mgdrag)
        deallocate(cnvctvmmixing)
        deallocate(ncnvctcfrac)
        deallocate(cnvctumflx)
        deallocate(cnvctdmflx)
        deallocate(cnvctdetmflx)
        deallocate(cnvctzgdrag)
        deallocate(cnvctmgdrag)      
      endif
!
!     FROM SOIL
!
      deallocate(smc)
      deallocate(stc)
      deallocate(sh2o)
      deallocate(SLDPTH)
      deallocate(RTDPTH)
      deallocate(SLLEVEL)
!
!     FROM VRBLS2D
!
      deallocate(u10)
      deallocate(v10)
      deallocate(tshltr)
      deallocate(qshltr)
      deallocate(mrshltr)
      deallocate(smstav)
      deallocate(ssroff)
      deallocate(bgroff)
      deallocate(vegfrc)
      deallocate(shdmin)
      deallocate(shdmax)
      deallocate(lai)
      deallocate(acsnow)
      deallocate(acgraup)
      deallocate(acfrain)
      deallocate(acsnom)
      deallocate(cmc)
      deallocate(sst)
      deallocate(qz0)
      deallocate(thz0)
      deallocate(uz0)
      deallocate(vz0)
      deallocate(qs)
      deallocate(ths)
      deallocate(sno)
      deallocate(snonc)
      deallocate(snoavg)
      deallocate(psfcavg)
      deallocate(t10m)
      deallocate(t10avg)
      deallocate(akhsavg)
      deallocate(akmsavg)
      deallocate(u10max)
      deallocate(v10max)
      deallocate(u10h)
      deallocate(v10h)
      deallocate(akms)
      deallocate(akhs)
      deallocate(cuprec)
      deallocate(acprec)
      deallocate(ancprc)
      deallocate(cuppt)
      deallocate(tsnow)
      deallocate(qvg)
      deallocate(qv2m)
      deallocate(qvl1)
      deallocate(rswin)
      deallocate(swddni)
      deallocate(swddif)
      deallocate(swdnbc)
      deallocate(swupbc)
      deallocate(swddnic)
      deallocate(swddifc)
      deallocate(swupt)
      deallocate(mean_frp)
      deallocate(ebb)
      deallocate(hwp)
      deallocate(smoke)
      deallocate(fv3dust)
      deallocate(taod5502d)
      deallocate(aerasy2d)
      deallocate(aerssa2d)
      deallocate(lwp)
      deallocate(iwp)
      deallocate(rlwin)
      deallocate(lwdnbc)
      deallocate(lwupbc)
      deallocate(rlwtoa)
      deallocate(rswtoa)
      deallocate(tg)
      deallocate(sfcshx)
      deallocate(sfclhx)
      deallocate(fis)
      deallocate(t500) 
      deallocate(t700)
      deallocate(z500)
      deallocate(z700)
      deallocate(teql)
      deallocate(ieql)
      deallocate(cfracl)
      deallocate(cfracm)
      deallocate(cfrach)
      deallocate(acfrst)
      deallocate(acfrcv)
      deallocate(hbot)
      deallocate(htop)
      deallocate(aswin)
      deallocate(alwin)
      deallocate(aswout)
      deallocate(alwout)
      deallocate(aswtoa)
      deallocate(alwtoa)
      deallocate(czen)
      deallocate(czmean)
      deallocate(sigt4)
      deallocate(rswout)
      deallocate(radot)
      deallocate(ncfrst)  ! real
      deallocate(ncfrcv)  ! real
      deallocate(smstot)
      deallocate(pctsno)
      deallocate(pshltr)
      deallocate(th10)
      deallocate(q10)
      deallocate(sr)
      deallocate(prec)
      deallocate(subshx)
      deallocate(snopcx)
      deallocate(sfcuvx)
      deallocate(sfcevp)
      deallocate(potevp)
      deallocate(z0)
      deallocate(ustar)
      deallocate(pblh)
      deallocate(pblhgust)
      deallocate(twbs)
      deallocate(qwbs)
      deallocate(sfcexc)
      deallocate(grnflx)
      deallocate(soiltb)
      deallocate(z1000)
      deallocate(slp)
      deallocate(pslp)
      deallocate(f)
      deallocate(albedo)
      deallocate(albase)
      deallocate(cldfra)
      deallocate(cprate)
      deallocate(cnvcfr)
      deallocate(ivgtyp)
      deallocate(isltyp)
      deallocate(hbotd)
      deallocate(htopd)
      deallocate(hbots)
      deallocate(htops)
      deallocate(cldefi)
      deallocate(islope)
      deallocate(si)
      deallocate(lspa)
      deallocate(rswinc)
      deallocate(vis)
      deallocate(pd)
      deallocate(mxsnal)
! add GFS fields
      deallocate(sfcux)
      deallocate(sfcvx)
      deallocate(sfcuxi)
      deallocate(sfcvxi)
      deallocate(avgalbedo)
      deallocate(avgcprate)
      deallocate(avgprec)
      deallocate(avgprec_cont)
      deallocate(avgcprate_cont)
      deallocate(ptop)
      deallocate(pbot)
      deallocate(avgcfrach)
      deallocate(avgcfracm)
      deallocate(avgcfracl)
      deallocate(avgtcdc)
      deallocate(auvbin)
      deallocate(auvbinc)
      deallocate(ptopl)
      deallocate(pbotl)
      deallocate(Ttopl)
      deallocate(ptopm)
      deallocate(pbotm)
      deallocate(Ttopm)
      deallocate(ptoph)
      deallocate(pboth)
      deallocate(Ttoph)
      deallocate(sfcugs)
      deallocate(sfcvgs)
      deallocate(pblcfr)
      deallocate(cldwork)
      deallocate(gtaux)
      deallocate(gtauy)
      deallocate(mdltaux)
      deallocate(mdltauy)
      deallocate(runoff)
      deallocate(maxtshltr)
      deallocate(mintshltr)
      deallocate(maxrhshltr)
      deallocate(minrhshltr)
      deallocate(maxqshltr)
      deallocate(minqshltr)
      deallocate(mixht)
      deallocate(epsr)
      deallocate(dzice)
      deallocate(alwinc)
      deallocate(alwoutc)
      deallocate(alwtoac)
      deallocate(aswinc)
      deallocate(aswoutc)
      deallocate(aswtoac)
      deallocate(aswintoa)
      deallocate(smcwlt)
      deallocate(suntime)
      deallocate(fieldcapa)
      deallocate(avisbeamswin)
      deallocate(avisdiffswin)
      deallocate(airbeamswin)
      deallocate(airdiffswin)
      deallocate(snowfall)
      deallocate(acond)
      deallocate(edir)
      deallocate(ecan)
      deallocate(etrans)
      deallocate(esnow)
      deallocate(avgedir)
      deallocate(avgecan)
      deallocate(avgetrans)
      deallocate(avgesnow)
      deallocate(avgpotevp)
      deallocate(aod550)
      deallocate(ti)
      deallocate(du_aod550)
      deallocate(ss_aod550)
      deallocate(su_aod550)
      deallocate(bc_aod550)
      deallocate(oc_aod550)
      deallocate(landfrac)
      deallocate(paha)
      deallocate(pahi)
      deallocate(tecan)
      deallocate(tetran)
      deallocate(tedir)
      deallocate(twa)
      deallocate(fdnsst)
      deallocate(pwat)
! GSD
      deallocate(rainc_bucket)
      deallocate(rainc_bucket1)
      deallocate(rainnc_bucket)
      deallocate(rainnc_bucket1)
      deallocate(pcp_bucket)
      deallocate(pcp_bucket1)
      deallocate(snow_bucket)
      deallocate(snow_bucket1)
      deallocate(graup_bucket)
      deallocate(graup_bucket1)
      deallocate(frzrn_bucket)
      deallocate(snow_acm)
      deallocate(qrmax)
      deallocate(tmax)
      deallocate(snownc)
      deallocate(graupelnc)
! SRD
      deallocate(wspd10max)
      deallocate(w_up_max)
      deallocate(w_dn_max)
      deallocate(w_mean)
      deallocate(refd_max)
      deallocate(prate_max)
      deallocate(fprate_max)
      deallocate(up_heli_max)
      deallocate(up_heli_max16)
      deallocate(up_heli_min)
      deallocate(up_heli_min16)
      deallocate(up_heli_max02)
      deallocate(up_heli_min02)
      deallocate(up_heli_max03)
      deallocate(up_heli_min03)
      deallocate(rel_vort_max)
      deallocate(rel_vort_max01)
      deallocate(rel_vort_maxhy1)
      deallocate(wspd10umax)
      deallocate(wspd10vmax)
      deallocate(refdm10c_max)
      deallocate(hail_max2d)
      deallocate(hail_maxk1)
      deallocate(hail_maxhailcast)
      deallocate(grpl_max)
      deallocate(up_heli)
      deallocate(up_heli16)
      deallocate(ltg1_max)
      deallocate(ltg2_max)
      deallocate(ltg3_max)
      deallocate(nci_ltg)
      deallocate(nca_ltg)
      deallocate(nci_wq)
      deallocate(nca_wq)
      deallocate(nci_refd)
      deallocate(nca_refd)

! CRA
      deallocate(REF_10CM)
      deallocate(REFC_10CM)
      deallocate(REF1KM_10CM)
      deallocate(REF4KM_10CM)
! CRA
      deallocate(U10mean)
      deallocate(V10mean)
      deallocate(SPDUV10mean)
      deallocate(SWRADmean)
      deallocate(SWNORMmean)
      deallocate(SNFDEN)
      deallocate(SNDEPAC)

!
!     FROM MASKS
!
      deallocate(hbm2)
      deallocate(sm)
      deallocate(sice)
      deallocate(lmh)  ! real
      deallocate(lmv)  ! real
      deallocate(gdlat)
      deallocate(gdlon)
      deallocate(dx)
      deallocate(dy)
      deallocate(htm)
      deallocate(vtm)

! add GFIP ICING
      deallocate(icing_gfip)
      deallocate(icing_gfis)

! add GTG turbulence
      deallocate(catedr)
      deallocate(mwt)
      deallocate(gtg)

!
      if (gocart_on .or. nasa_on) then
! Deallocate GOCART fields
! vrbls4d
        deallocate(dust)
        deallocate(salt)
        deallocate(soot)
        deallocate(waso)
        deallocate(suso)
      if (nasa_on) then
        deallocate(no3)
        deallocate(nh4)
      endif
        deallocate(pp25)
        deallocate(pp10)
! vrbls3d
        deallocate(ext)
        deallocate(asy)
        deallocate(ssa)
        deallocate(sca)
        deallocate(duem)
        deallocate(dusd)
        deallocate(dudp)
        deallocate(duwt)
        deallocate(dusv)
        deallocate(suem)
        deallocate(susd)
        deallocate(sudp)
        deallocate(suwt)
        deallocate(ocem)
        deallocate(ocsd)
        deallocate(ocdp)
        deallocate(ocwt)
        deallocate(ocsv)
        deallocate(bcem)
        deallocate(bcsd)
        deallocate(bcdp)
        deallocate(bcwt)
        deallocate(bcsv)
        deallocate(ssem)
        deallocate(sssd)
        deallocate(ssdp)
        deallocate(sswt)
        deallocate(sssv)
        deallocate(rhomid)
! vrbls2d
        deallocate(dusmass)
        deallocate(ducmass)
        deallocate(dusmass25)
        deallocate(ducmass25)
        deallocate(susmass)
        deallocate(sucmass)
        deallocate(susmass25)
        deallocate(sucmass25)
        deallocate(ocsmass)
        deallocate(occmass)
        deallocate(ocsmass25)
        deallocate(occmass25)
        deallocate(bcsmass)
        deallocate(bccmass)
        deallocate(bcsmass25)
        deallocate(bccmass25)
        deallocate(sssmass)
        deallocate(sscmass)
        deallocate(sssmass25)
        deallocate(sscmass25)
        deallocate(dustcb)
        deallocate(occb)
        deallocate(bccb)
        deallocate(sulfcb)
        deallocate(pp25cb)
        deallocate(pp10cb)
        deallocate(sscb)
        if (nasa_on) then
        deallocate(no3cb)
        deallocate(nh4cb)
        endif
        deallocate(dustallcb)
        deallocate(ssallcb)
        deallocate(dustpm)
	deallocate(dustpm10)
        deallocate(sspm)
	deallocate(maod)
      endif
!
! HWRF RRTMG output 
      deallocate(acswupt)
      deallocate(swdnt)
      deallocate(acswdnt)
! UPP_MATH MODULE DIFFERENTIAL EQUATIONS
      deallocate(ddvdx)
      deallocate(ddudy)
      deallocate(uuavg)

! AQF
      if (aqf_on) then
        deallocate(avgozcon)
        deallocate(avgpmtf)
        deallocate(aqm_aod550)
      endif

      end
