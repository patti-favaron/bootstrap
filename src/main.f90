program main

    use bootstrap

    implicit none

    ! Locals
    character(len=256)                  :: sPathName
    character(len=256)                  :: sOutputFile
    character(len=64)                   :: sBuffer
    integer                             :: iRetCode
    integer                             :: iYear, iMonth, iDay, iHour
    integer                             :: iBootSize
    integer                             :: iNumData
    integer                             :: iNumQuadruples
    real, dimension(:), allocatable     :: rvTimeStamp
    real, dimension(:,:), allocatable   :: rmX
    real(8)                             :: rTimeRandom
    real(8)                             :: rTimeSampling
    real(8)                             :: rTimeSorting
    real, dimension(4)                  :: rvInf
    real, dimension(4)                  :: rvAvg
    real, dimension(4)                  :: rvSup
    integer                             :: iTrial
    integer                             :: iLUN

    ! Constants
    character(len=*), parameter :: FILE = "/Users/patriziafavaron/Documents/Research/bootstrap/aux/test_case/test.csv"

    ! Get parameters
    if(command_argument_count() /= 4) then
        print *, "Test program for bootstrap"
        print *
        print *, "Usage:"
        print *
        print *, "  ./bootstrap <Input_Path> <Date_Time> <Boot_Size> <Output_File>"
        print *
        print *, "where"
        print *
        print *, "  <Date_Time> ::= YYYYMMDDHH"
        print *
        print *, "Copyright 2026 by Patrizia Favaron"
        print *, "This is open-source software, covered by the MIT license"
        print *
        stop
    end if
    call get_command_argument(1, sPathName)
    call get_command_argument(2, sBuffer)
    read(sBuffer, "(i4,2i2,i2)", iostat=iRetCode) iYear, iMonth, iDay, iHour
    if(iRetCode /= 0) then
        print *, "Parameter '<Date_Time>' is invalid (shoud be a number with form yyyymmddhh)"
        stop
    end if
    call get_command_argument(3, sBuffer)
    read(sBuffer, *, iostat=iRetCode) iBootSize
    if(iRetCode /= 0) then
        print *, "Parameter '<Num_Samples>' is invalid"
        stop
    end if
    if(iBootSize < 10) then
        print *, "Parameter '<Num_Samples>' is less than 10"
        stop
    end if
    call get_command_argument(4, sOutputFile)

    ! Get data
    print *, "Reading data"
    iRetCode = get_mfc2(sPathName, iYear, iMonth, iDay, iHour, rvTimeStamp, rmX, iNumQuadruples)
    if(iRetCode /= 0) then
        print *, "Data file not read"
        stop
    end if
    if(iNumQuadruples /= size(rvTimeStamp)) then
        print *, "Data other than sonic quadruples found; using only quadruples"
    end if
    print *, "Data read, ", iNumQuadruples, "found eventually."
    print *

    ! Compute the 95% bootstrap confidence limits
    iRetCode = boot_multi_mean(rmX, iBootSize, rvInf, rvAvg, rvSup, rTimeRandom, rTimeSampling, rTimeSorting)

    ! Write results
    print *
    print *, "Writing results"
    open(newunit=iLUN, file=sOutputFile, status='unknown', action='write')
    write(iLUN, "(a,a)") &
        'Trial, U.Inf, U.Avg, U.Sup, V.Inf, V.Avg, V.Sup, W.Inf, W.Avg, W.Sup, T.Inf, T.Avg, T.Sup, ', &
        'Rand.Time, Smpl.Time, Sort.Time'
    write(iLUN, "(i4.4,2('-',i2.2),1x,i2.2,':00:00',12(',',f9.3),3(',',f6.3))") &
        iYear, iMonth, iDay, iHour, &
        rvInf(1), rvAvg(1), rvSup(1), &
        rvInf(2), rvAvg(2), rvSup(2), &
        rvInf(3), rvAvg(3), rvSup(3), &
        rvInf(4), rvAvg(4), rvSup(4), &
        rTimeRandom, rTimeSampling, rTimeSorting
    close(iLUN)

    print *, "*** End Job ***"

contains

    function get_mfc2(sPathName, iYear, iMonth, iDay, iHour, rvTimeStamp, rmX, iNumData) result(iRetCode)

        ! Routine arguments
        character(len=*), intent(in)                    :: sPathName
        integer, intent(in)                             :: iYear
        integer, intent(in)                             :: iMonth
        integer, intent(in)                             :: iDay
        integer, intent(in)                             :: iHour
        real, dimension(:), allocatable, intent(out)    :: rvTimeStamp
        real, dimension(:,:), allocatable, intent(out)  :: rmX
        integer, intent(out)                            :: iNumData
        integer                                         :: iRetCode

        ! Locals
        character(len=256)  :: sFileName
        integer             :: iNumBytes
        integer             :: iNumLines
        integer             :: iErrCode
        integer             :: iLUN
        integer(2)          :: iTimeStamp
        integer(2)          :: iU
        integer(2)          :: iV
        integer(2)          :: iW
        integer(2)          :: iT

        ! Assume success (will falsify on failure)
        iRetCode = 0

        ! Estimate file size and reserve data space
        write(sFileName, "(a,'/',i4.4,2i2.2,'.',i2.2,'R')") trim(sPathName), iYear, iMonth, iDay, iHour
        inquire(file=sFileName, size=iNumBytes)
        if(iNumBytes <= 0) then
            iRetCode = 1
            return
        end if
        iNumLines = iNumBytes / 10
        if(allocated(rvTimeStamp)) deallocate(rvTimeStamp)
        if(allocated(rmX)) deallocate(rmX)
        allocate(rvTimeStamp(iNumLines))
        allocate(rmX(iNumLines,4))

        ! Get file contents
        iNumData = 0
        open(newunit=iLUN, file=SfileName, status='unknown', action='read', access='stream')
        do
            read(iLUN, iostat=iErrCode) iTimeStamp, iV, iU, iW, iT
            if(iErrCode /= 0) exit
            if(iTimeStamp < 5000) then
                iNumData = iNumData + 1
                rmX(iNumData, 2) = iV / 100.0
                rmX(iNumData, 1) = iU / 100.0  ! Not a joke: U and V are really exchanged in these data sets
                rmX(iNumData, 3) = iW / 100.0
                rmX(iNumData, 4) = iT / 100.0
            end if
        end do
        close(iLUN)

    end function get_mfc2

end program main
