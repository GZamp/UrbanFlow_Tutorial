c-----------------------------------------------------------------------
c
c     user subroutines required by nek5000
c
c     Parameters used by this set of subroutines:

c-----------------------------------------------------------------------
      subroutine uservp (ix,iy,iz,ieg)
      include 'SIZE'
      include 'NEKUSE'          ! UDIFF, UTRANS

      UDIFF =0.0
      UTRANS=0.0

      return
      end
c-----------------------------------------------------------------------
      subroutine userf  (ix,iy,iz,ieg)
      
      include 'SIZE'
      include 'NEKUSE'          ! FF[XYZ]
      include 'PARALLEL'
      include 'TRIPD'

      integer ix,iy,iz,ieg,iel
      real*8 uss(lx1,ly1,lz1,lelv), vss(lx1,ly1,lz1,lelv)

      real*8 usponge(lx1,ly1,lz1,lelv),
     $     vsponge(lx1,ly1,lz1,lelv), wsponge(lx1,ly1,lz1,lelv)

      COMMON /SPONGE/ usponge,vsponge,wsponge,uss,vss

      ffx = 0.0
      ffy = 0.0
      ffz = 0.0

      iel = gllel(ieg)
      call trip_comp(ix,iy,iz,iel)

      uss(ix,iy,iz,iel) = ffx 
      vss(ix,iy,iz,iel) = ffy
      
cc      iel=GLLEL(ieg)
cc      do il= 1, trip_nline
cc         ipos = trip_map(ix,iy,iz,iel,il)
cc         ffy = ffy + trip_ftrp(ipos,il)*trip_fsmth(ix,iy,iz,iel,il)
cc      enddo
cc      uss(ix,iy,iz,iel) = ffy
      
      return
      end
c-----------------------------------------------------------------------
      subroutine userq  (ix,iy,iz,ieg)
      include 'SIZE'
      include 'NEKUSE'          ! QVOL

      QVOL   = 0.0

      return
      end
c-----------------------------------------------------------------------
      subroutine userchk
      implicit none
      include 'SIZE'            !
      include 'TSTEP'           ! ISTEP, lastep, time
      include 'INPUT'           ! IF3D, PARAM
      include 'SOLN'            ! T
      include 'MASS'            ! BM1 for lambda2
      include 'USERPAR'         ! L2FREQ
      include 'TRIPD'
cc      include 'CHKPOINT'

      integer lt
      parameter (lt = lx1*ly1*lz1*lelv)

      real*8 usponge(lx1,ly1,lz1,lelv),
     $     vsponge(lx1,ly1,lz1,lelv), wsponge(lx1,ly1,lz1,lelv)

      real*8 uss(lx1,ly1,lz1,lelv), vss(lx1,ly1,lz1,lelv)
      
      COMMON /SPONGE/ usponge,vsponge,wsponge,uss,vss
      real pvel(lx1,ly1,lz1,lelt)
      real wk1(lx1*ly1*lz1),wk2(lx1*ly1*lz1)


      logical exist_rst, ifsave
      

!    Read initial mesh 
cc         inquire(file='duct.IC',exist=exist_rst)
cc         if (exist_rst) then
cc            if(nid.eq.0)then
cc               write(*,*) '------------------------------------'
cc               write(*,*) 'READ  IC  as the Fringe input'
cc               write(*,*) '------------------------------------'
cc            end if
cc            initc(1) = 'duct.IC'
cc            call setics
cc            call opcopy(usponge,vsponge,wsponge,vx,vy,vz)
cc         end if
!     Check for restart files
      
!     start framework
      if (ISTEP.eq.0) then
         call frame_start
!     set volume flow parameters
cc         param(54) = uparam(1)
cc         param(55) = uparam(2)
      endif

!     monitor simulation
      call frame_monitor

!     save/load files for full-restart
      call chkpt_main

! Calculate and output Lambda2
!-------------------------------------------------- 
      IFTO = .TRUE.
      L2FREQ = uparam(3)
      if (mod(ISTEP,L2FREQ).eq.0) then
         if (NID.eq.0) write(6,*) ISTEP,IOSTEP,TIME,' compute lambda2'
         call lambda2(T(1,1,1,1,1))
         call col2  (T(1,1,1,1,1),bm1,lt)
         call dssum (T(1,1,1,1,1),nx1,ny1,nz1)
         call col2  (T(1,1,1,1,1),binvm1,lt)
         call outpost(vx,vy,vz,pr,t,'la2')
cc         call outpost(vx,vy,vz,pr,uss,'trx')
c     c         call outpost(vx,vy,vz,pr,vss,'try')

!     Map pressure to velocity mesh
         call mappr(pvel,pr,wk1,wk2)
         call outpost(vx,vy,vz,pr,pvel,'lap')

         
      endif
!--------------------------------------------------

!     for tripping
      call trip_update
      
!     for statistics
      call stat_avg

!     collect time series
      ifsave = .true. ! no I/O correlation with other packages

      call tsrs_main(ifsave)


!     finalise framework
      if (ISTEP.eq.NSTEPS.or.LASTEP.eq.1) then
         call frame_end
      endif
     
      return
      end
c-----------------------------------------------------------------------
      subroutine userbc (ix,iy,iz,iside,ieg)
      include 'SIZE'
      include 'NEKUSE'          ! UX, UY, UZ, TEMP, X, Y
      include 'PARALLEL'
      
      real p1u,p2u,p3u,p4u,p5u,p6u,p7u,p8u,p9u
      real p1v,p2v,p3v,p4v,p5v,p6v,p7v,p8v,p9v
      real yend,Uend,Vend
      integer e
      real U0,delta

      U0 = 1.0                  ! characteristic velocity
      delta = 0.1               ! small positive constant
      pa=0.0

!     *** START OF INPUT

      yend= 0.2302325581395349
      Uend= 1.0000000000000000
      Vend= 0.0032885826666667

      p1u= -4678221.3544147275000000
      p2u= 4984769.2178074559000000
      p3u= -2134722.2151771067000000
      p4u= 459140.3962073480900000
      p5u= -49429.8467091279450000
      p6u= 2168.0351842820955000
      p7u= -50.3534738339082680
      p8u= 13.1336843411078410
      p9u= -0.0005554230070279

      p1v= -1775.9946634274711000
      p2v= 7671.9870195726680000
      p3v= -5838.1721572628676000
      p4v= 1850.4053482520674000
      p5v= -275.2669161309750100
      p6v= 16.1950688019275120
      p7v= 0.0290532327904566
      p8v= 0.0043088806400491
      p9v= -0.0000063770830184

!     *** END OF INPUT

      if(y.le.yend) then
         ux=p1u*y**8+p2u*y**7+p3u*y**6+p4u*y**5+p5u*y**4+p6u*y**3+
     &        p7u*y**2+p8u*y+p9u
         uy=p1v*y**8+p2v*y**7+p3v*y**6+p4v*y**5+p5v*y**4+p6v*y**3+
     &        p7v*y**2+p8v*y+p9v
      else
         ux=Uend
         uy=Vend
      endif
      
      uz=0.0

      e = gllel(ieg)
      
      if (cbu.eq.'o  ') then
         pa = dongOutflow(ix,iy,iz,e,iside,U0,delta)
c         write(*,*) 'pa=',pa
      endif
      
      return
      end
c-----------------------------------------------------------------------
      subroutine useric (ix,iy,iz,ieg)
      include 'SIZE'
      include 'NEKUSE'          ! UX, UY, UZ, TEMP, Z
      include 'PARALLEL'

      real p1u,p2u,p3u,p4u,p5u,p6u,p7u,p8u,p9u
      real p1v,p2v,p3v,p4v,p5v,p6v,p7v,p8v,p9v
      real yend,Uend,Vend
      real U0,delta

      U0=1.0 ! characteristic velocity
      delta=0.1 ! small positive constant
      pa=0.0 ! pressure

!     *** START OF INPUT

      yend= 0.2302325581395349
      Uend= 1.0000000000000000
      Vend= 0.0032885826666667

      p1u= -4678221.3544147275000000
      p2u= 4984769.2178074559000000
      p3u= -2134722.2151771067000000
      p4u= 459140.3962073480900000
      p5u= -49429.8467091279450000
      p6u= 2168.0351842820955000
      p7u= -50.3534738339082680
      p8u= 13.1336843411078410
      p9u= -0.0005554230070279

      p1v= -1775.9946634274711000
      p2v= 7671.9870195726680000
      p3v= -5838.1721572628676000
      p4v= 1850.4053482520674000
      p5v= -275.2669161309750100
      p6v= 16.1950688019275120
      p7v= 0.0290532327904566
      p8v= 0.0043088806400491
      p9v= -0.0000063770830184

!     *** END OF INPUT

      if(y.le.yend) then
         ux=p1u*y**8+p2u*y**7+p3u*y**6+p4u*y**5+p5u*y**4+p6u*y**3+
     &        p7u*y**2+p8u*y+p9u
         uy=p1v*y**8+p2v*y**7+p3v*y**6+p4v*y**5+p5v*y**4+p6v*y**3+
     &        p7v*y**2+p8v*y+p9v
      else
         ux=Uend
         uy=Vend
      endif
      
      uz=0.0
      
      return
      end

C-----------------------------------------------------------------------
      function dongOutflow(ix,iy,iz,iel,iside,u0,delta)

      include 'SIZE'
      include 'SOLN'
      include 'GEOM'

      real sn(3)

      ux = vx(ix,iy,iz,iel)
      uy = vy(ix,iy,iz,iel)
      uz = vz(ix,iy,iz,iel)

      call getSnormal(sn,ix,iy,iz,iside,iel)
      vn = ux*sn(1) + uy*sn(2) + uz*sn(3)
      S0 = 0.5*(1.0 - tanh(vn/u0/delta))

      dongOutflow = -0.5*(ux*ux+uy*uy+uz*uz)*S0

      return
      end
c-----------------------------------------------------------------------
      subroutine usrdat
      include 'SIZE'
      include 'TOTAL'

      return
      end
c-----------------------------------------------------------------------
      subroutine usrdat2
      include 'SIZE'
      include 'TOTAL'

c      do iel=1,nelv
c         do ifc=1,2*ndim
c            id_face = bc(5,ifc,iel,1)
c            if (id_face.eq.1) then
c               write(*,*) 'F1:',cbc(ifc,iel,1)
c            elseif (id_face.eq.2) then
c               write(*,*) 'F2:',cbc(ifc,iel,1)
c            elseif (id_face.eq.3) then
c               write(*,*) 'F3:',cbc(ifc,iel,1)
c            elseif (id_face.eq.4) then
c               write(*,*) 'F4:',cbc(ifc,iel,1)
c            elseif (id_face.eq.5) then
c               write(*,*) 'F5:',cbc(ifc,iel,1)
c            elseif (id_face.eq.6) then
c               write(*,*) 'F6:',cbc(ifc,iel,1)
c            elseif (id_face.eq.7) then
c               write(*,*) 'F7:',cbc(ifc,iel,1)
c            endif
c         enddo
c      enddo

      do iel=1,nelv
         do ifc=1,2*ndim
            id_face = bc(5,ifc,iel,1)
cc            if (id_face.eq.1) then
cc               cbc(ifc,iel,1) = 'v  '
            if (id_face.eq.2) then
               cbc(ifc,iel,1) = 'o  '
            elseif (id_face.eq.4) then
               cbc(ifc,iel,1) = 'ON '
            endif
         enddo
      enddo
      
      return
      end
c-----------------------------------------------------------------------
      subroutine usrdat3
      include 'SIZE'
      include 'INPUT'
      include 'NEKUSE'
      
      return
      end
c-----------------------------------------------------------------------  
      subroutine user_ref_reinit
      implicit none

      call trip_reset

      return
      end
c-----------------------------------------------------------------------
      subroutine user_ref_makef
      implicit none

      call trip_frcs_get(.false.)

      return
      end
c-----------------------------------------------------------------------

c automatically added by makenek
      subroutine usrsetvert(glo_num,nel,nx,ny,nz) ! to modify glo_num
      integer*8 glo_num(1)

      return
      end

c automatically added by makenek
      subroutine userqtl

      call userqtl_scig

      return
      end
