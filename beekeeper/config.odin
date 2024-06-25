//+build windows
package bkpr

// @note even though it is called DEBUG_TRACKER_ENABLED, everything that "debug-related" is going to be marked and check 
// with this variable in "when" statement(s)
BKPR_DEBUG_TRACKER_ENABLED :: #config(BKPR_DEBUG_TRACKER_ENABLED, false);