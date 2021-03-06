#
# Makefile for ESMA components.
#
# REVISION HISTORY:
#
# 09Jun2003  da Silva  First crack. 
#

# Make sure ESMADIR is defined
# ----------------------------
ifndef ESMADIR
       ESMADIR := $(PWD)/../..
endif

# Compilation rules, flags, etc
# -----------------------------
  include $(ESMADIR)/Config/ESMA_base.mk  # Generic stuff
  include $(ESMADIR)/Config/ESMA_arch.mk  # System dependencies
  include $(ESMADIR)/Config/GMAO_base.mk  # Generic stuff

#                  ---------------------
#                  Standard ESMA Targets
#                  ---------------------

esma_help help:
	@echo "Standard ESMA targets:"
	@echo "% make esma_install    (builds and install under ESMADIR)"
	@echo "% make esma_clean      (removes deliverables: *.[aox], etc)"
	@echo "% make esma_distclean  (leaves in the same state as cvs co)"
	@echo "% make esma_doc        (generates PDF, installs under ESMADIR)"
	@echo "% make esma_help       (this message)"
	@echo "Environment:"
	@echo "      ESMADIR = $(ESMADIR)"
	@echo "      BASEDIR = $(BASEDIR)"
	@echo "         ARCH = $(ARCH)"
	@echo "         SITE = $(SITE)"

THIS := $(shell basename `pwd`)
LIB  = lib$(THIS).a

#ALLDIRS = tests

SUBDIRS = $(wildcard $(ALLDIRS) )

TARGETS = esma_install esma_clean esma_distclean esma_doc \
          install clean distclean doc

$(TARGETS): 
	@ t=$@; argv="$(SUBDIRS)" ;\
	  for d in $$argv; do			 \
	    ( cd $$d				;\
	      echo ""; echo Making $$t in `pwd`          ;\
	      $(MAKE) -e $$t ) \
	  done
	$(MAKE) local_$@

local_esma_install local_install: $(LIB)
	$(MKDIR) $(ESMALIB) $(ESMAINC)/$(THIS)
	$(CP) -p *.a            $(ESMALIB)
	$(CP) -p *.mod          $(ESMAINC)/$(THIS)

local_esma_clean local_clean:
	-$(RM) *~ *.[aox] *.mod *.x

local_esma_distclean local_distclean:
	-$(RM) *~ *.[aoxd] *.mod *.x

local_esma_doc local_doc:
	@echo "Target $@ not yet implemented in $(THIS)"


#                  --------------------
#                  User Defined Targets
#                  --------------------


SRCS := kinds.F90 nc_diag_read.F90 ncdr_alloc_assert.f90 ncdr_attrs.f90 ncdr_attrs_fetch.f90 \
        ncdr_check.f90 ncdr_climsg.F90 ncdr_dims.f90 ncdr_global_attrs.f90 ncdr_global_attrs_fetch.f90 \
        ncdr_realloc_mod.F90 ncdr_state.f90 ncdr_types.f90 ncdr_vars.f90 ncdr_vars_fetch.f90 netcdf_unlimdims.F90
OBJS := $(addsuffix .o, $(basename $(SRCS))) 
DEPS := $(addsuffix .d, $(basename $(SRCS))) 

INC_DIRS = . $(INC_GMAO_SHARED)
MOD_DIRS = . $(INC_DIRS) $(INC_ESMF) \
             $(foreach dir,$(SUBDIRS),$(ESMAINC)/$(dir))

USER_FDEFS  = $(D)_REAL8_ $(D)ERROR_TRACEBACK
USER_FINCS  = $(foreach dir,$(INC_DIRS),$(I)$(dir)) 
USER_FMODS  = $(foreach dir,$(MOD_DIRS),$(M)$(dir))

FREAL = $(FREAL4) # for now, require 32 bit reals (R4)

vpath % $(MOD_DIRS)

$(LIB) lib : $(OBJS)
	$(AR) $(AR_FLAGS) $(LIB) $(OBJS)


# Hack to prevent remaking dep files during cleaning
# --------------------------------------------------
  ifneq ($(findstring clean,$(MAKECMDGOALS)),clean)
    -include $(DEPS)
  endif

#.


  -include $(ESMADIR)/Config/ESMA_post.mk  # ESMA additional targets, macros

