! Sequential _slow_ implementation of bootstrap on the mean of a data vector
!
module bootstrap

    use fast_select

    implicit none
    private

    public :: boot_mean
    public :: boot_multi_mean

contains

    function boot_mean( &
        rvX, &
        iBootSize, &
        rInf, &
        rAvg, &
        rSup, &
        rTimeRandom, &
        rTimeSampling, &
        rTimeSorting &
    ) result(iRetCode)

        ! Routine arguments
        real, dimension(:), intent(in)                  :: rvX
        integer, intent(in)                             :: iBootSize
        real, intent(out)                               :: rInf
        real, intent(out)                               :: rAvg
        real, intent(out)                               :: rSup
        real(8), intent(out)                            :: rTimeRandom
        real(8), intent(out)                            :: rTimeSampling
        real(8), intent(out)                            :: rTimeSorting
        integer                                         :: iRetCode

        ! Locals
        real, dimension(:), allocatable         :: rvSample
        integer, dimension(:), allocatable      :: ivIdx
        real, dimension(:), allocatable         :: rvRand
        integer                                 :: i
        integer                                 :: j
        integer                                 :: n
        integer                                 :: iItem
        integer                                 :: iSample
        integer                                 :: iSel025
        integer                                 :: iSel975
        real, dimension(:), allocatable         :: rvBootMean
        real(8)                                 :: rTimeFrom
        real(8)                                 :: rTimeTo

        ! Assume success (will falsify on failure)
        iRetCode = 0

        ! Initialize random number generator
        call random_init(repeatable=.false., image_distinct=.true.)

        ! Check parameters
        n = size(rvX)
        if(n < 10) then
            iRetCode = 1
            return
        end if
        if(iBootSize <= 0) then
            iRetCode = 2
            return
        end if

        ! **********************
        ! * Bootstrap sampling *
        ! **********************

        ! Reserve space for output
        if(allocated(rvBootMean)) deallocate(rvBootMean)
        allocate(rvBootMean(iBootSize))

        ! Build the actual samples
        rTimeRandom   = 0.d0
        rTimeSampling = 0.d0
        allocate(rvRand(n))
        allocate(ivIdx(n))
        rvBootMean = 0.0
        do iSample = 1, iBootSize

            ! Generate the index of sampling with repetitions
            call cpu_time(rTimeFrom)
            call random_number(rvRand)
            ivIdx = int(rvRand * n) + 1
            call cpu_time(rTimeTo)
            rTimeRandom = rTimeRandom + rTimeTo - rTimeFrom
            call cpu_time(rTimeFrom)
            rvBootMean(iSample) = 0.0
            do i = 1, n
                j = ivIdx(i)
                rvBootMean(iSample) = rvBootMean(iSample) + rvX(j)
            end do
            rvBootMean(iSample) = rvBootMean(iSample) / n
            call cpu_time(rTimeTo)
            rTimeSampling = rTimeSampling + rTimeTo - rTimeFrom

        end do
        deallocate(ivIdx)
        deallocate(rvRand)

        ! Compute conventional average
        rAvg = sum(rvX) / n

        ! *********************************
        ! * Compute the confidence limits *
        ! *********************************
        call cpu_time(rTimeFrom)
        allocate(rvSample(iBootSize))
        iSel025 = 0.025 * iBootSize
        iSel975 = 0.975 * iBootSize
        rvSample = rvBootMean
        call quick_select(rvSample, iSel025)
        rInf = rvSample(iSel025)
        call quick_select(rvSample, iSel975)
        rSup = rvSample(iSel975)
        deallocate(rvSample)
        call cpu_time(rTimeTo)
        rTimeSorting = rTimeSorting + rTimeTo - rTimeFrom

    end function boot_mean


    function boot_multi_mean( &
        rmX, &
        iBootSize, &
        rvInf, &
        rvAvg, &
        rvSup, &
        rTimeRandom, &
        rTimeSampling, &
        rTimeSorting &
    ) result(iRetCode)

        ! Routine arguments
        real, dimension(:,:), intent(in)                :: rmX
        integer, intent(in)                             :: iBootSize
        real, dimension(:), intent(out)                 :: rvInf
        real, dimension(:), intent(out)                 :: rvAvg
        real, dimension(:), intent(out)                 :: rvSup
        real(8), intent(out)                            :: rTimeRandom
        real(8), intent(out)                            :: rTimeSampling
        real(8), intent(out)                            :: rTimeSorting
        integer                                         :: iRetCode

        ! Locals
        real, dimension(:), allocatable         :: rvSample
        integer, dimension(:), allocatable      :: ivIdx
        real, dimension(:), allocatable         :: rvRand
        integer                                 :: i
        integer                                 :: j
        integer                                 :: n
        integer                                 :: iItem
        integer                                 :: iSample
        integer                                 :: iSel025
        integer                                 :: iSel975
        real, dimension(:,:), allocatable       :: rmBootMean
        real(8)                                 :: rTimeFrom
        real(8)                                 :: rTimeTo

        ! Assume success (will falsify on failure)
        iRetCode = 0

        ! Initialize random number generator
        call random_init(repeatable=.false., image_distinct=.true.)

        ! Check parameters
        n = size(rmX, dim=1)
        if(n < 10) then
            iRetCode = 1
            return
        end if
        if(iBootSize <= 0) then
            iRetCode = 2
            return
        end if

        ! **********************
        ! * Bootstrap sampling *
        ! **********************

        ! Reserve space for output
        allocate(rmBootMean(iBootSize, 4))

        ! Build the actual samples
        rTimeRandom   = 0.d0
        rTimeSampling = 0.d0
        allocate(rvRand(n))
        allocate(ivIdx(n))
        rmBootMean = 0.0
        do iSample = 1, iBootSize

            ! Generate the index of sampling with repetitions
            call cpu_time(rTimeFrom)
            call random_number(rvRand)
            ivIdx = int(rvRand * n) + 1
            call cpu_time(rTimeTo)
            rTimeRandom = rTimeRandom + rTimeTo - rTimeFrom

            ! Actuate sampling
            call cpu_time(rTimeFrom)
            rmBootMean(iSample,:) = 0.0
            do i = 1, n
                j = ivIdx(i)
                rmBootMean(iSample,:) = rmBootMean(iSample,:) + rmX(j,:)
            end do
            rmBootMean(iSample,:) = rmBootMean(iSample,:) / n
            call cpu_time(rTimeTo)
            rTimeSampling = rTimeSampling + rTimeTo - rTimeFrom

        end do
        deallocate(ivIdx)
        deallocate(rvRand)

        ! Compute conventional average
        rvAvg = sum(rmX, dim=1) / n

        ! *********************************
        ! * Compute the confidence limits *
        ! *********************************
        call cpu_time(rTimeFrom)
        do i = 1, 4
            allocate(rvSample(iBootSize))
            iSel025 = 0.025 * iBootSize
            iSel975 = 0.975 * iBootSize
            rvSample = rmBootMean(:,i)
            call quick_select(rvSample, iSel025)
            rvInf(i) = rvSample(iSel025)
            call quick_select(rvSample, iSel975)
            rvSup(i) = rvSample(iSel975)
            deallocate(rvSample)
        end do
        call cpu_time(rTimeTo)
        rTimeSorting = rTimeSorting + rTimeTo - rTimeFrom

    end function boot_multi_mean

end module bootstrap
