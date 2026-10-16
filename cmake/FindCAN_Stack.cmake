if(NOT TARGET isobus::isobus)
  include(FetchContent)
  FetchContent_Declare(
    CAN_Stack
    GIT_REPOSITORY https://github.com/gunicsba/AgIsoStack-plus-plus.git
    GIT_TAG 9b1a7dbe9ddafb511bc1005e166d24a7dbe82157)
  FetchContent_MakeAvailable(CAN_Stack)
endif()
