*** Settings ***
Documentation       Robocorp cert 2

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive

*** Tasks ***
Order Robots from RobotSpareBin Industries Inc - Lvl2 - Tejus
    Open the robot orders web
    Get orders
    Fill the form using the data from the csv file
    Archive output PDFs
    [Teardown]    Close RobotSpareBin Browser

*** Keywords ***
Open the robot orders web
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    Download    https://robotsparebinindustries.com/orders.csv      ${OUTPUT_DIR}${/}data${/}orders.csv     overwrite=True

Close the annoying modal
    ${condition}=  Run Keyword And Return Status    Element Should Be Visible    css:div.alert-buttons    
    Run Keyword If    ${condition}    Click Button    css:div.alert-buttons > button:nth-child(1)

Preview and save screenshot of the robot for an order
    [Arguments]    ${screenshot}
    Wait Until Element Is Visible    id:robot-preview-image
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(1)
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(2)
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(3)
    Screenshot    id:robot-preview-image    ${screenshot}

Download and store the receipt
    [Arguments]    ${order_number}    ${screenshot}
    Wait Until Element Is Visible    id:order-completion
    ${order_completion_html}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${order_completion_html}    ${OUTPUT_DIR}${/}completed_order${/}robot_${order_number}.pdf    overwrite=True
    ${screenshots}=    Create List
    ...    ${screenshot}
    Add Files To Pdf    ${screenshots}        ${OUTPUT_DIR}${/}completed_order${/}robot_${order_number}.pdf    overwrite=True

Fill the form using the data from the csv file, preview and submit for an order
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    ${screenshot}=     Set Variable    ${OUTPUT_DIR}${/}previews${/}robot_${order}[Order number].png
    WHILE    True    limit=10
        Click Button    id:preview    
        ${condition}=  Run Keyword And Return Status    Preview and save screenshot of the robot for an order    ${screenshot}
        IF     ${condition} == True    BREAK
    END
    
    WHILE    True    limit=10
        Wait And Click Button   id:order
        ${condition}=  Run Keyword And Return Status    Download and store the receipt     ${order}[Order number]    ${screenshot}
        IF     ${condition} == True    BREAK
    END
    #Run Keyword If    ${condition}    Wait And Click Button   id:order
    #Run Keyword If    ${condition}    Download and store the receipt     ${order}[Order number]    ${screenshot}
Fill the form using the data from the csv file
    ${orders}=    Read table from CSV    ${OUTPUT_DIR}${/}data${/}orders.csv    header=True
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Close the annoying modal
        Fill the form using the data from the csv file, preview and submit for an order    ${order}
        Wait And Click Button   id:order-another
    END

Archive output PDFs
    Archive Folder With ZIP   ${OUTPUT_DIR}${/}completed_order${/}    ${OUTPUT_DIR}${/}all_completed_order.zip   recursive=True  include=*.pdf  exclude=/.*
    @{files}                  List Archive             all_completed_order.zip
    FOR  ${file}  IN  ${files}
        Log  ${file}
    END
    #Add To Archive            .${/}..${/}missing.robot  tasks.zip
    #&{info}                   Get Archive Info

Close RobotSpareBin Browser
    Close Browser