*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the temp-receipts and the images.
...

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Loop the orders
    Create a ZIP file of receipt PDF files
    Cleanup Outputs
    [Teardown]    Close the browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the orders file, read it as a table, and return the results
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}
    ${orders}=    Read table from CSV    orders.csv
    RETURN    ${orders}

Give up rights
    Click Button    css:button.btn.btn-danger
    Wait Until Element Is Not Visible    css:button.btn.btn-danger

Loop the orders
    ${orders}=    Download the orders file, read it as a table, and return the results
    FOR    ${order}    IN    @{orders}
        Give up rights
        Fill the form    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    10x    0.2 sec    Submit the order
        Store the order receipt as a PDF file    ${order}
        Take a screenshot of the robot image    ${order}
        Embed the robot screenshot to the receipt PDF file    ${order}
        Order another robot
    END

Fill the form
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    address    ${order}[Address]A

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    Wait Until Element Is Visible    receipt    timeout=0.2

Store the order receipt as a PDF file
    [Arguments]    ${order}
    ${receipt}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}${/}temp-receipts${/}${order}[Order number].pdf

Take a screenshot of the robot image
    [Arguments]    ${order}
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}temp-robot-previews${/}${order}[Order number].png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${order}
    Open Pdf    ${OUTPUT_DIR}${/}temp-receipts${/}${order}[Order number].pdf
    ${files}=    Create List    ${OUTPUT_DIR}${/}temp-robot-previews${/}${order}[Order number].png
    Add Files To Pdf
    ...    ${files}
    ...    ${OUTPUT_DIR}${/}temp-receipts${/}${order}[Order number].pdf
    ...    append=${True}
    Close Pdf    ${OUTPUT_DIR}${/}temp-receipts${/}${order}[Order number].pdf

Order another robot
    Click Button    order-another

Create a ZIP file of receipt PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}${/}temp-receipts    ${OUTPUT_DIR}${/}receipts-archive.zip

Cleanup Outputs
    Remove Directory    ${OUTPUT_DIR}${/}temp-robot-previews    recursive=${True}
    Remove Directory    ${OUTPUT_DIR}${/}temp-receipts    recursive=${True}

Close the browser
    Close Browser
