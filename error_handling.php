<?php
ini_set('display_errors', 0);

function _phpconsole_internal_errorOccured($errno, $errstr, $errfile, $errline, $errcontex) {
	switch ($errno) {
	case E_ERROR:
	    $errtype = "Fatal error:";
	    break;
	case E_WARNING:
	    $errtype = "Warning:";
	    break;
	case E_NOTICE:
	    $errtype = "Notice:";
	    break;
	case E_CORE_ERROR:
	    $errtype = "Core Error:";
	    break;
	case E_CORE_WARNING:
	    $errtype = "Core Warning:";
	    break;
	case E_USER_ERROR:
	    $errtype = "User-Generated Error:";
	    break;
	case E_USER_WARNING:
	    $errtype = "User-Generated Warning:";
	    break;
	case E_USER_NOTICE:
	    $errtype = "User-Generated Notice:";
	    break;
	case E_STRICT:
	    $errtype = "Suggested Change:";
	    break;
	default:
	    $errtype = "Other Error:";
	}
	echo $errtype . " " . str_replace(":", "-", $errstr) . " on line $errline\n";
	die(1);
}
set_error_handler("_phpconsole_internal_errorOccured");
?>