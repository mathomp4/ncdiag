module ncdr_vars
    use kinds
    use netcdf
    use ncdr_types
    use ncdr_state
    use ncdr_alloc_assert
    use ncdr_vars_fetch
    implicit none
    
    interface nc_diag_read_lookup_var
        module procedure nc_diag_read_id_lookup_var, &
            nc_diag_read_noid_lookup_var
    end interface nc_diag_read_lookup_var
    
    interface nc_diag_read_check_var
        module procedure nc_diag_read_id_check_var, &
            nc_diag_read_noid_check_var
    end interface nc_diag_read_check_var
    
    interface nc_diag_read_get_var_ndims
        module procedure nc_diag_read_id_get_var_ndims, &
            nc_diag_read_noid_get_var_ndims
    end interface nc_diag_read_get_var_ndims
    
    interface nc_diag_read_get_var_type
        module procedure nc_diag_read_id_get_var_type, &
            nc_diag_read_noid_get_var_type
    end interface nc_diag_read_get_var_type
    
    interface nc_diag_read_ret_var_dims
        module procedure nc_diag_read_id_ret_var_dims, &
            nc_diag_read_noid_ret_var_dims
    end interface nc_diag_read_ret_var_dims
    
    interface nc_diag_read_get_var_dims
        module procedure nc_diag_read_id_get_var_dims, &
            nc_diag_read_noid_get_var_dims
    end interface nc_diag_read_get_var_dims
    
    contains
        subroutine nc_diag_read_parse_file_vars(file_ncid, file_index, num_vars)
            integer(i_long), intent(in)                :: file_ncid
            integer(i_long), intent(in)                :: file_index
            integer(i_long), intent(in)                :: num_vars
            
            integer(i_long)                            :: i, j
            
            character(len=NF90_MAX_NAME)               :: var_name
            
            ncdr_files(file_index)%nvars = num_vars
            allocate(ncdr_files(file_index)%vars(num_vars))
            
            do i = 1, num_vars
                ncdr_files(file_index)%vars(i)%var_id = i
                
                call check(nf90_inquire_variable(file_ncid, i, &
                    name = var_name, &
                    ndims = ncdr_files(file_index)%vars(i)%var_ndims, &
                    xtype = ncdr_files(file_index)%vars(i)%var_type))
                
                ncdr_files(file_index)%vars(i)%var_name = trim(var_name)
                
                allocate(ncdr_files(file_index)%vars(i)%var_dim_inds( &
                    ncdr_files(file_index)%vars(i)%var_ndims))
                
                call check(nf90_inquire_variable(file_ncid, i, &
                    dimids = ncdr_files(file_index)%vars(i)%var_dim_inds))
                
                ! Since the dimensions indicies are aligned to NetCDF's
                ! indicies, we don't need to do any more analysis.
                ! We're done with indices!
                
                ! Now, let's actually use them:
                allocate(ncdr_files(file_index)%vars(i)%var_dim_sizes( &
                    ncdr_files(file_index)%vars(i)%var_ndims))
                
                do j = 1, ncdr_files(file_index)%vars(i)%var_ndims
                    ncdr_files(file_index)%vars(i)%var_dim_sizes(j) = &
                        ncdr_files(file_index)%dims( &
                            ncdr_files(file_index)%vars(i)%var_dim_inds(j) &
                            )%dim_size
                end do
            end do
        end subroutine nc_diag_read_parse_file_vars
        
        function nc_diag_read_id_lookup_var(file_ncid, var_name) result(var_index)
            integer, intent(in)            :: file_ncid
            character(len=*), intent(in)   :: var_name
            
            integer                        :: var_index
            
            call ncdr_check_ncid(file_ncid)
            
            do var_index = 1, ncdr_files(file_ncid)%nvars
                if (ncdr_files(file_ncid)%vars(var_index)%var_name == var_name) &
                    return
            end do
            
            ! Otherwise, return -1!
            var_index = -1
        end function nc_diag_read_id_lookup_var
        
        function nc_diag_read_noid_lookup_var(var_name) result(var_index)
            character(len=*), intent(in)   :: var_name
            
            integer                        :: var_index
            
            call ncdr_check_current_ncid
            
            var_index = nc_diag_read_id_lookup_var(current_ncid, var_name)
        end function nc_diag_read_noid_lookup_var
        
        function nc_diag_read_id_check_var(file_ncid, var_name) result(var_exists)
            integer, intent(in)            :: file_ncid
            character(len=*), intent(in)   :: var_name
            
            logical                        :: var_exists
            
            call ncdr_check_ncid(file_ncid)
            
            if (nc_diag_read_id_lookup_var(file_ncid, var_name) == -1) then
                var_exists = .FALSE.
                return
            end if
            
            var_exists = .TRUE.
        end function nc_diag_read_id_check_var
        
        function nc_diag_read_noid_check_var(var_name) result(var_exists)
            character(len=*), intent(in)   :: var_name
            
            logical                        :: var_exists
            
            call ncdr_check_current_ncid
            
            if (nc_diag_read_lookup_var(var_name) == -1) then
                var_exists = .FALSE.
                return
            end if
            
            var_exists = .TRUE.
        end function nc_diag_read_noid_check_var
        
        function nc_diag_read_id_get_var_ndims(file_ncid, var_name) result(var_ndims)
            integer, intent(in)            :: file_ncid
            character(len=*), intent(in)   :: var_name
            
            integer(i_long)                :: var_index, var_ndims
            
            call ncdr_check_ncid(file_ncid)
            
            var_index = nc_diag_read_id_assert_var(file_ncid, var_name)
            
            var_ndims = ncdr_files(nc_diag_read_get_index_from_ncid(file_ncid))%vars(var_index)%var_ndims
        end function nc_diag_read_id_get_var_ndims
        
        function nc_diag_read_noid_get_var_ndims(var_name) result(var_ndims)
            character(len=*), intent(in)   :: var_name
            
            integer(i_long)                :: var_ndims
            
            call ncdr_check_current_ncid
            
            var_ndims = nc_diag_read_id_get_var_ndims(current_ncid, var_name)
        end function nc_diag_read_noid_get_var_ndims
        
        function nc_diag_read_id_get_var_type(file_ncid, var_name) result(var_type)
            integer, intent(in)            :: file_ncid
            character(len=*), intent(in)   :: var_name
            
            integer(i_long)                :: var_index, var_type
            
            call ncdr_check_ncid(file_ncid)
            
            var_index = nc_diag_read_id_assert_var(file_ncid, var_name)
            
            var_type = ncdr_files(nc_diag_read_get_index_from_ncid(file_ncid))%vars(var_index)%var_type
        end function nc_diag_read_id_get_var_type
        
        function nc_diag_read_noid_get_var_type(var_name) result(var_type)
            character(len=*), intent(in)   :: var_name
            
            integer(i_long)                :: var_type
            
            call ncdr_check_current_ncid
            
            var_type = nc_diag_read_id_get_var_type(current_ncid, var_name)
        end function nc_diag_read_noid_get_var_type
        
        function nc_diag_read_id_ret_var_dims(file_ncid, var_name) result(var_dims)
            integer, intent(in)                        :: file_ncid
            character(len=*), intent(in)               :: var_name
            
            integer(i_long)                            :: var_index, var_ndims, i
            integer(i_long), dimension(:), allocatable :: var_dims
            
            call ncdr_check_ncid(file_ncid)
            
            var_index = nc_diag_read_id_assert_var(file_ncid, var_name)
            
            var_ndims = nc_diag_read_id_get_var_ndims(file_ncid, var_name)
            
            allocate(var_dims(var_ndims))
            
            do i = 1, var_ndims
                var_dims(i) = &
                    ncdr_files(nc_diag_read_get_index_from_ncid(file_ncid))%dims( &
                        ncdr_files(nc_diag_read_get_index_from_ncid(file_ncid))%vars(var_index)%var_dim_inds(i) &
                        )%dim_size
            end do
        end function nc_diag_read_id_ret_var_dims
        
        function nc_diag_read_noid_ret_var_dims(var_name) result(var_dims)
            character(len=*), intent(in)                :: var_name
            integer(i_long), dimension(:), allocatable  :: var_dims
            
            integer(i_long)                             :: var_ndims
            
            call ncdr_check_current_ncid
            
            var_ndims = nc_diag_read_id_get_var_ndims(current_ncid, var_name)
            
            allocate(var_dims(var_ndims))
            
            var_dims = nc_diag_read_id_ret_var_dims(current_ncid, var_name)
        end function nc_diag_read_noid_ret_var_dims
        
        subroutine nc_diag_read_id_get_var_dims(file_ncid, var_name, var_ndims, var_dims)
            integer, intent(in)                      :: file_ncid
            character(len=*), intent(in)             :: var_name
            integer(i_long), intent(inout), optional :: var_ndims
            integer(i_long), intent(inout), dimension(:), allocatable, optional :: var_dims
            
            integer(i_long)                :: var_index, v_ndims, i
            
            call ncdr_check_ncid(file_ncid)
            
            var_index = nc_diag_read_id_assert_var(file_ncid, var_name)
            
            v_ndims = nc_diag_read_id_get_var_ndims(file_ncid, var_name)
            
            if (present(var_ndims)) &
                var_ndims = v_ndims
            
            if (present(var_dims)) then
                if (.NOT. allocated(var_dims)) then
                    allocate(var_dims(v_ndims))
                else
                    if (size(var_dims) /= v_ndims) &
                        call error("Invalid allocated array size for variable dimensions size storage!")
                end if
                
                do i = 1, v_ndims
                    var_dims(i) = &
                        ncdr_files(nc_diag_read_get_index_from_ncid(file_ncid))%dims( &
                            ncdr_files(nc_diag_read_get_index_from_ncid(file_ncid))%vars(var_index)%var_dim_inds(i) &
                            )%dim_size
                end do
            end if
        end subroutine nc_diag_read_id_get_var_dims
        
        subroutine nc_diag_read_noid_get_var_dims(var_name, var_ndims, var_dims)
            character(len=*), intent(in)             :: var_name
            integer(i_long), intent(inout), optional :: var_ndims
            integer(i_long), intent(inout), dimension(:), allocatable, optional :: var_dims
            
            call ncdr_check_current_ncid
            
            if (present(var_ndims)) then
                if (present(var_dims)) then
                    call nc_diag_read_id_get_var_dims(current_ncid, var_name, var_ndims, var_dims)
                else
                    call nc_diag_read_id_get_var_dims(current_ncid, var_name, var_ndims)
                end if
            else
                if (present(var_dims)) then
                    call nc_diag_read_id_get_var_dims(current_ncid, var_name, var_dims = var_dims)
                else
                    ! Why you want to do this, I dunno...
                    call nc_diag_read_id_get_var_dims(current_ncid, var_name)
                end if
            end if
        end subroutine nc_diag_read_noid_get_var_dims
        
        subroutine test_nc_diag_read_get_var_dims
            integer(i_long)                            :: var_ndims
            integer(i_long), dimension(:), allocatable :: var_dims
            var_dims = nc_diag_read_ret_var_dims(0, "test")
            var_dims = nc_diag_read_ret_var_dims("test")
            
            call nc_diag_read_get_var_dims(0, "test")
            call nc_diag_read_get_var_dims(0, "test", var_ndims)
            call nc_diag_read_get_var_dims(0, "test", var_ndims, var_dims)
            call nc_diag_read_get_var_dims(0, "test", var_dims = var_dims)
            call nc_diag_read_get_var_dims(0, "test")
            
            call nc_diag_read_get_var_dims("test", var_ndims)
            call nc_diag_read_get_var_dims("test", var_ndims, var_dims)
            call nc_diag_read_get_var_dims("test", var_dims = var_dims)
            call nc_diag_read_get_var_dims("test")
        end subroutine test_nc_diag_read_get_var_dims
end module ncdr_vars
