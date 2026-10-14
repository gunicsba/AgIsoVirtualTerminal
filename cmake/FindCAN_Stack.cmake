if(NOT TARGET isobus::isobus)
  include(FetchContent)
  FetchContent_Declare(
    CAN_Stack
    GIT_REPOSITORY https://github.com/gunicsba/AgIsoStack-plus-plus.git
    GIT_TAG 79bbb6a670886545b19da4b1eb4a9bfcc13a0d43)
  FetchContent_MakeAvailable(CAN_Stack)
endif()
