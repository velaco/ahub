server <- function(input, output, session){
    
    ans1 <- reactiveVal(NULL)
    ans2 <- reactiveVal(NULL)
    logcontent <- reactiveVal(NULL)
    err <- reactiveVal(NULL)
    
    
    # output$swagger1 <- renderUI({
    #     if(apis_fetched){
    #         tags$iframe(srcdoc=HTML(as.character(GET(node1$swagger_url) %>% content)),
    #                     width='100%', height='500px', seamless=NA) 
    #     }
    # })
    # 
    # output$prophetdemo <- renderUI({
    #     if(apis_fetched){
    #         tags$iframe(srcdoc=HTML(as.character(GET(node2$swagger_url) %>% content)),
    #                        width='100%', height='500px', seamless=NA) 
    #     }
    # })
    # 
    # output$swaggerlink1 <- renderUI({
    #     if(apis_fetched){
    #         a(href = node1$swagger_url, target="_blank", 'Goto Swagger UI')
    #     }
    # })
    
    observeEvent(input$logrefresh, {
        #loglines <- read_lines('../process.log') %>% 
        #    sort(decreasing = T) %>% 
        #    head(20) 
        loglines <- content(boss_api$ops$get_all_logs()) %>% bind_rows()
        logcontent(loglines)
    })
    
    observeEvent(input$exec_batch1, {
        if(is.null(node_api[[1]]$errmsg)){ # only when operations are fetched
            response <- node_api[[1]]$ops[[1]]()
            ans1(httr::content(response))    
        }else{
            err(node_api[[1]]$errmsg)
        }
    })
    
    observeEvent(input$exec_thread1, {
        if(is.null(node_api[[1]]$errmsg)){ # only when operations are fetched
            response <- node_api[[1]]$ops[[2]]()
            ans1(httr::content(response))    
        }else{
            err(node_api[[1]]$errmsg)
        }
    })
    
    observeEvent(input$exec_batch2, {
        if(is.null(node_api[[2]]$errmsg)){ # only when operations are fetched
            response <- node_api[[2]]$ops[[1]]()
            ans2(httr::content(response))    
        }else{
            err(node_api[[2]]$errmsg)
        }
    })
    
    observeEvent(input$exec_thread2, {
        if(is.null(node_api[[2]]$errmsg)){ # only when operations are fetched
            response <- node_api[[2]]$ops[[2]]()
            ans2(httr::content(response))    
        }else{
            err(node_api[[2]]$errmsg)
        }
    })
    
    output$result1 <- renderPrint({
        ans1()
    })
    
    output$result2 <- renderPrint({
        ans2()
    })
    
    output$logfile <- renderDataTable({
        datatable(logcontent())
    })
    
    output$error <- renderPrint({
        cat(err(), fill=T)
    })
    
    # debugging request header
    output$summary <- renderText({
        ls(env=session$request)
    })
    
    output$headers <- renderUI({
        selectInput("header", "Header:", ls(env=session$request))
    })
    
    output$value <- renderText({
        if (nchar(input$header) < 1 || !exists(input$header, envir=session$request)){
            return("NULL");
        }
        return (get(input$header, envir=session$request));
    })
    
    
    
}


