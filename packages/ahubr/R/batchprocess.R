



#' Run a function as a daily executable batch process in the AHUB framework
#'
#' @param process_name name of the process to be saved
#' @param myfun function, which is to be executed in batchmode
#' @param force TRUE/FALSE force execution of function if process has already run today
#' @param arglist named list of arguments for myfun
#' @param debug TRUE/FALSE endpoint for call to boss is switched to .ahubEnv$debughost instead of "nginx"
#'
#' @return list with message, logitems, status and process id
#' @export
#'
#' @import glue future futile.logger
#' @importFrom magrittr %>%
#'
#' @examples
#' \dontrun{
#' daily_batch_process(dummy_process, "test", arglist = list(t=1))
#' }
daily_batch_process <- function(myfun,
                              process_name = "batch",
                              arglist = list(),
                              force=F,
                              debug = F
                              ) {
    #function(force = F, ...) {
        #process_name <- 'batch' # this name is crucial for process logging and status checking
        if(debug) switch_debug()
        pid <- get_pid(process_name) # get the last process id for this process
        pid_info <- get_pid_info(pid) # get the info to the pid

        # has the process already finished today
        run_today <-
            pid_info$time %>% substr(1, 8) %>% lubridate::ymd() == Sys.Date() &
            pid_info$status == 'finished'

        # check if process has not run today and is not finished and force is FALSE
        if (!run_today | as.numeric(force)) {
            # if yes, check if process is not running
            if (pid_info$status != 'running' & init_future()) {
                # if yes start process
                if (pid_info$status != 'init') pid <- create_pid(process_name)

                f <- future({
                    if(debug) switch_debug()
                    # init logging
                    pid_log(glue('Process {process_name} started.'))
                    ahubr:::set_pid_status(pid, 'running')

                    # do some stuff ##################
                    ans <- try(do.call(myfun, arglist))
                    #################################

                    if(inherits(ans, "try-error")){
                        pid_log(glue('Process {process_name} encountered error {ans[1]}'))
                        ahubr:::set_pid_status(pid, 'error')
                    }else{
                        # wrap up
                        pid_log(glue('Process {process_name} finished'))
                        ahubr:::set_pid_status(pid, 'finished')
                    }
                    return(TRUE)
                    }, packages=c("futile.logger", "glue", "ahubr"),
                    globals = c("pid", "process_name", "myfun", "arglist", "debug")
                )
                output <-
                    list(
                        msg = glue("Process {process_name} started."),
                        log = get_pid_log(pid),
                        status = 'started',
                        pid = pid
                    )
            } else{
                # if not return log and status
                output <-
                    list(
                        msg = glue("Process {process_name} currently running."),
                        log = get_pid_log(pid),
                        status = 'running',
                        pid = pid
                    )
            }
        } else{
            # if not, do nothing and return log
            output <- list(
                msg = glue("Process {process_name} finished!"),
                log = get_pid_log(pid),
                status = 'finished',
                pid = pid
            )
        }
        output
    #}
}


#' Initiate multisession future for batch process
#'
#' @return TRUE/FALSE if successful
#'
#' @import future
init_future <- function(){
    if(!.ahubEnv$future_init){
        status <- try(plan(multisession), silent=TRUE)
        if(!inherits(status, 'try-error')){
            assign("future_init", TRUE, envir = .ahubEnv)
            return(TRUE)
        }else{
            flog.error('Could not initialise multisession future for batch processing.')
            return(FALSE)
        }
    }else{
        return(TRUE)
    }
}











