if(NOT TARGET isobus::isobus)
  include(FetchContent)
  FetchContent_Declare(
    CAN_Stack
    GIT_REPOSITORY https://github.com/gunicsba/AgIsoStack-plus-plus.git
    GIT_TAG 1b2eda8d68283c5559b5162416f7db768d51ea64)
  FetchContent_MakeAvailable(CAN_Stack)
endif()
