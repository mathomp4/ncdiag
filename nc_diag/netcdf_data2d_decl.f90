        !===============================================================
        ! nc_diag_data2d - data2d handling (declaration)
        !===============================================================
        ! DO NOT COMPILE THIS DIRECTLY! THIS IS MEANT TO BE INCLUDED
        ! INSIDE A LARGER F90 SOURCE!
        ! If you compile this directly, you WILL face the WRATH of your
        ! compiler!
        !---------------------------------------------------------------
        ! Depends on: nothing
        ! 
        ! (Note that the subroutines portion of this part of the program
        ! has dependencies - but the declaration part doesn't require
        ! anything!)
        !---------------------------------------------------------------
        ! nc_diag_data2d stores data2d data as NetCDF4 global
        ! attributes. The nc_diag_data2d subroutines temporarily cache
        ! any data2d data until write, where it will be set by
        ! NF90_PUT_ATT().
        !---------------------------------------------------------------
        ! This file provides the interface wrapper for the specific
        ! subroutines.
        
        ! diag_data2d struct
        !   This is a super type to store information for the diag data2d,
        !   to be stored in the NetCDF4 file.
        !   
        !   Storage works as follows:
        !     = Add elements to the data2d structure through the subroutine
        !       nc_diag_data2d().
        !         -> The element name is first added to the names variable
        !            within diag_data2d. Allocation (and/or reallocation)
        !            occurs if necessary.
        !         -> The type of the element is stored into the types
        !            variable within diag_data2d, using the constants
        !            available above. Allocation (and/or reallocation)
        !            occurs if necessary.
        !         -> If the type of the element is a vector, the vectored
        !            logical is set to true. Otherwise, it's left as false.
        !         -> If the type of the element is a vector, the
        !            corresponding index vector is set to the number of
        !            elements in the vector.
        !         -> Then the array size and count are validated for the
        !            specific type. Allocation (and/or reallocation) for the
        !            specific type array occurs if necessary.
        !         -> Once ready, we add the actual data into diag_data2d.
        !            If the type of the element is a vector, we simply
        !            append the elements to the vector, since we can now
        !            keep track.
        !         -> Finally, we increment any counters as necessary, and
        !            we call it a day!
        !     = When everything is done, nc_diag_write() is called. This
        !       will trigger nc_diag_data2d_write(), which will do the 
        !       following:
        !         -> Fetch the total number of attributes.
        !         -> Iterate through the names, types, and logical vectored
        !            variables, using the total number of attributes.
        !         -> Based on the types and logical vectored variable,
        !            fetch the actual data from the right spot.
        !         -> Write said data using the NetCDF4 subroutines.
        !         -> Increment our own counters to keep track of how much
        !            we read, especially for the individual variables and
        !            types.
        !         -> Not as tedious as queueing the data!
        !   
        !   Variables:
        !     names    - names of data2d information (attributes) to store.
        !                This is a 1-D array of names - dimensions based on
        !                the number of attributes stored.
        !     types    - types (specified as an integer constants located
        !                above) for each attribute. This is a 1-D array of
        !                integers - dimensions based on the number of
        !                attributes stored.
        !     vectored - whether the attribute stores a 1D vector or not.
        !                This is a 1-D array of integers - dimensions based
        !                on the number of attributes stored.
        !     total    - the total number of attributes in diag_data2d
        !     asize    - array size for each type. This is a 1-D array of
        !                integers - dimensions based on the number of TYPES
        !                available, including vectored types. In this case,
        !                we have 6 single types, plus 5 "hidden" vectored
        !                types (via m_***_vi), so the dimension is 11.
        !     acount   - array count for each type - this is the number of
        !                elements already stored for each type, including
        !                vectored types. The dimensions are the same as
        !                asize - in this case, it's 11.
        !     m_***    - data storage variables, single element array,
        !                dimensions based on the number and type of
        !                attributes stored. If I store one short, one float,
        !                and one double from scratch, then m_short, m_float,
        !                and m_double will have a length of 1 each. The rest
        !                of the m_*** will be empty.
        !     m_***_vi - length index storage for vectored data, dimensions
        !                based on the number and type of vectored attributes
        !                stored. If I store one short vector, one float
        !                vector, and one double vector from scratch, then
        !                m_short_vi, m_float_vi, and m_double_vi will have
        !                a length of 1 vector each. The rest of the m_***_vi
        !                will be empty. These are only populated when a
        !                vector of data is added.
        type diag_d2d_iarr
            integer(i_long),    dimension(:), allocatable :: index_arr
            integer(i_long),    dimension(:), allocatable :: length_arr
            integer(i_long)                               :: icount
            integer(i_long)                               :: isize
        end type diag_d2d_iarr
        
        type diag_data2d
            character(len=100), dimension(:), allocatable :: names
            integer(i_byte),    dimension(:), allocatable :: types
            type(diag_d2d_iarr),dimension(:), allocatable :: stor_i_arr
            integer(i_byte),    dimension(:), allocatable :: alloc_sia_multi
            
            ! Maximum string length - only used when the variable
            ! definitions are locked.
            integer(i_long),    dimension(:), allocatable :: max_str_lens
            
            ! Maximum variable length - only used when the variable
            ! definitions are locked.
            integer(i_long),    dimension(:), allocatable :: max_lens
            
            ! Relative indexes - for buffer flushing, keep track of the
            ! relative indexes when we flush data. We store the
            ! variable count here so that we can reference it when we
            ! reset our variable counter to zero, allowing us to reuse
            ! memory while still preserving data order!
            integer(i_long),    dimension(:), allocatable :: rel_indexes
            
            ! Total variables
            integer(i_long)                               :: total = 0
            integer(i_long)                               :: prealloc_total = 0
            
            ! Array sizes
            integer(i_long),  dimension(6)                :: asize
            integer(i_long),  dimension(6)                :: acount
            
            ! # of times we needed to realloc simple data2d
            ! also the multiplier factor for allocation (2^x)
            integer(i_byte)                               :: alloc_s_multi
            
            ! # of times we needed to realloc data2d data storage
            ! also the multiplier factor for allocation (2^x)
            integer(i_byte),  dimension(6)                :: alloc_m_multi
            
            ! # of times we needed to realloc data2d INDEX data storage
            ! also the multiplier factor for allocation (2^x)
            integer(i_byte),  dimension(6)                :: alloc_mi_multi
            
            ! Did we write anything out yet?
            logical                                       :: def_lock
            logical                                       :: data_lock
            
            ! Strict checking for bounds?
            ! (Making sure that the sizes are consistent!)
            logical                                       :: strict_check
            
            integer(i_byte),     dimension(:),allocatable :: m_byte
            integer(i_short),    dimension(:),allocatable :: m_short
            integer(i_long),     dimension(:),allocatable :: m_long
            real(r_single),      dimension(:),allocatable :: m_rsingle
            real(r_double),      dimension(:),allocatable :: m_rdouble
            character(len=1000), dimension(:),allocatable :: m_string
            
            integer(i_long),    dimension(:), allocatable :: var_dim_ids
            integer(i_long),    dimension(:), allocatable :: var_ids
        end type diag_data2d
        
        type(diag_data2d), allocatable :: diag_data2d_store
        
        interface nc_diag_data2d
            module procedure nc_diag_data2d_byte, &
                nc_diag_data2d_short, nc_diag_data2d_long, &
                nc_diag_data2d_rsingle, nc_diag_data2d_rdouble, &
                nc_diag_data2d_string
        end interface nc_diag_data2d
