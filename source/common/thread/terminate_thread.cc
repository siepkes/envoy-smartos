#include "source/common/thread/terminate_thread.h"

#include <sys/types.h>

#include <csignal>

#if defined(__sun) || defined(__illumos__)
#include <pthread.h>
#endif

#include "source/common/common/logger.h"

namespace Envoy {
namespace Thread {
namespace {
#if defined(__linux__)
pid_t toPlatformTid(int64_t tid) { return static_cast<pid_t>(tid); }
#elif defined(__APPLE__)
uint64_t toPlatformTid(int64_t tid) { return static_cast<uint64_t>(tid); }
#endif
} // namespace

bool terminateThread(const ThreadId& tid) {
#if defined(__sun) || defined(__illumos__)
  // On illumos the ThreadId holds a pthread_t (see posix/thread_impl.cc). kill() operates on
  // processes, not threads, so signal the specific thread directly. pthread_kill() returns 0
  // on success.
  return pthread_kill(static_cast<pthread_t>(tid.getId()), SIGABRT) == 0;
#elif !defined(WIN32)
  // Assume POSIX-compatible system and signal to the thread.
  return kill(toPlatformTid(tid.getId()), SIGABRT) == 0;
#else
  // Windows, currently unsupported termination of thread.
  ENVOY_LOG_MISC(error, "Windows is currently unsupported for terminateThread.");
  return false;
#endif
}

} // namespace Thread
} // namespace Envoy
