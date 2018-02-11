<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<head>
    <title>Search AD</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta http-equiv="pragma" content="no-cache">
    <style type="text/css">
        <!--body {
            font-family: Verdana, Arial, Tahoma, "Trebuchet MS", sans-serif;
            font-size: 12px;
            line-height: 1.2em;
            text-align: left;
            margin-top: 0;
            margin-bottom: 0;
            background-color: #F7F7F7;
        }

        #wrap {
            width: 960px;
            color: #555;
            padding: 10px;
            text-align: left;
            background: #FFF;
            margin-top: 0;
            margin-right: auto;
            margin-bottom: 0;
            margin-left: auto;
            height: 100%;
        }

        #top {
            width: 960px;
            text-align: right;
            margin: 10px auto 5px auto;
            color: #333;
            font-size: 10px;
        }

        #top p {
            margin: 2px;
            padding: 0;
        }

        #top a {
            color: #777;
            border-bottom: 1px dotted #aaa;
        }

        #top a:hover {
            color: #fff;
            text-decoration: none;
            border-bottom: 1px dotted #fff;
        }
        /* Headline */

        #headline {
            width: 960px;
            text-align: center;
            margin: 5px 0px 0px 0;
            border: 1px solid #ccc;
            color: #4D699D;
        }

        #headline p {
            margin: 2px;
            padding: 10px;
            font-size: 20px;
            letter-spacing: -1px;
        }
        /* Content */

        #content {
            float: left;
            text-align: left;
            width: 960px;
            margin: 10px 0 0 0;
            font-size: 12px;
        }

        #content h2 {
            font-size: 1.7em;
            letter-spacing: -1px;
            clear: left;
            border-bottom: 2px solid #ccc;
        }

        #content h3 {
            font-size: 10pt;
            letter-spacing: -1px;
        }

        #content h5 {
            font-size: 1.1em;
            letter-spacing: -1px;
            clear: left;
            border-bottom: 2px solid #ccc;
        }

        #content h2 a,
        #content h3 a {
            font-weight: 700;
        }

        #content p {
            margin: 0 0 5px;
        }

        #content a:hover {
            color: #222;
            border-bottom: 1px solid #000;
        }

        #content ul,
        #content ol {
            margin: 0 0 15px 10px;
            padding: 0 0 0 10px;
        }

        #content ul li,
        #content ol li {
            margin: 0 0 10px 10px;
        }

        #content ul ul,
        #content ol ol {
            margin: 5px 0 5px 10px;
        }
        /* Footer */

        #footer {
            clear: both;
            font-size: 10px;
            width: 960px;
            line-height: 1.5em;
            color: #333;
            margin: 5px auto 10px auto;
            padding: 0;
        }

        #footer p {
            margin: 0;
            padding: 0;
        }

        #box-table-a {
            font-family: Verdana, Arial, Tahoma, "Trebuchet MS", sans-serif;
            font-size: 1em;
            margin: 0px;
            width: 100%;
            text-align: left;
            border-collapse: collapse;
        }

        #box-table-a th {
            font-size: 15px;
            font-weight: normal;
            text-align: left;
            padding: 8px;
            background: #b9c9fe;
            border-top: 4px solid #aabcfe;
            border-bottom: 1px solid #fff;
            color: #039;
        }

        #box-table-a td {
            padding: 8px;
            background: #e8edff;
            border-bottom: 1px solid #fff;
            color: #069;
            border-top: 1px solid transparent;
        }

        #box-table-a tr:hover td {
            background: #d0dafd;
            color: #339;
        }

        #box-table-b {
            font-family: Verdana, Arial, Tahoma, "Trebuchet MS", sans-serif;
            font-size: 1em;
            margin: 0px;
            width: 100%;
            text-align: left;
            border-collapse: collapse;
        }

        #box-table-b th {
            font-size: 15px;
            font-weight: normal;
            text-align: left;
            padding: 8px;
            background: #FF9;
            border-top: 4px solid #FF6;
            border-bottom: 1px solid #fff;
            color: #009;
        }

        #box-table-b td {
            padding: 8px;
            background: #FFC;
            border-bottom: 1px solid #fff;
            color: #009;
            border-top: 1px solid transparent;
        }
        /* Various classes */

        .left {
            float: left;
            width: 49%;
            text-align: left;
        }

        .left33 {
            float: left;
            width: 33%;
            text-align: left;
        }

        .left65 {
            float: left;
            width: 65%;
            text-align: left;
        }

        .right {
            float: right;
            width: 49%;
            text-align: right;
        }

        .right33 {
            float: right;
            width: 33%;
            text-align: right;
        }

        .right65 {
            float: right;
            width: 65%;
            text-align: right;
        }

        .textleft {
            text-align: left;
        }

        .textright {
            text-align: right;
        }

        .textcenter {
            text-align: center;
        }

        .introtext,
        .introtext a {
            font-weight: 700;
        }

        .clear {
            visibility: hidden;
            clear: both;
            height: 1px;
        }

        .hide {
            display: none;
        }

        -->
    </style>
</head>

<body>
    <div id="wrap">
        <div id="top" class="show">
            <p>Skip to: <a href="#footer">bottom</a></p>
        </div>
        <div id="headline" class="show">
            <p>VDL Nedcar - Active Directory Search</p>
        </div>
        <%
Response.CodePage = 65001    
Response.CharSet = "utf-8"

dim groupname
groupname = Ucase( Request.QueryString("groupname") )
searchgroupname = groupname

if StrComp(groupname, "ADMIN") = 0 then
    searchgroupname = "*shit*"
end if
if StrComp(groupname, "DOMAIN USERS") = 0 then
    searchgroupname = "*shit*"
end if
if StrComp(groupname, "DOMAIN ADMINS") = 0 then
    searchgroupname = "*shit*"
end if
if StrComp(groupname, "DOMAIN GUESTS") = 0 then
    searchgroupname = "*shit*"
end if
if StrComp(groupname, "DOMAIN PRINTOPS") = 0 then
    searchgroupname = "*shit*"
end if
if StrComp(groupname, "DOMAIN OPERATORS") = 0 then
    searchgroupname = "*shit*"
end if
if StrComp(groupname, "DOMAIN COMPUTERS") = 0 then
    searchgroupname = "*shit*"
end if
if StrComp(groupname, "DOMAIN CONTROLLERS") = 0 then
    searchgroupname = "*shit*"
end if
if StrComp(groupname, "ENTERPRISE ADMINS") = 0 then
    searchgroupname = "*shit*"
end if
if StrComp(groupname, "SCHEMA ADMINS") = 0 then
    searchgroupname = "*shit*"
end if
if StrComp(groupname, "PROTECTED USERS") = 0 then
    searchgroupname = "*shit*"
end if

Set rootDSE = GetObject("LDAP://rootDSE") 'detect the own domain
domainDN = rootDSE.Get("defaultNamingContext")
    
FuncADuser = "nedcar.nl\svcaddComp2Domain"
FuncADpassword = "AddComp2Domain" 
 
' Create ADO DB connection
Set ado = Server.CreateObject("ADODB.Connection")
Set objCommand = CreateObject("ADODB.Command")
ado.Provider = "ADSDSOObject" 
ado.Properties("User ID") = FuncADuser
ado.Properties("Password") = FuncADpassword
ado.Properties("Encrypt Password") = True

' Open ADO connection
ado.Open "Active Directory Provider"
Set objCommand.ActiveConnection = ado
objCommand.Properties("Page Size") = 1000
objCommand.Properties("Searchscope") = ADS_SCOPE_SUBTREE

' Lets search for a group
ldapFilter = "(&(objectClass=group)(sAMAccountName=" & searchgroupname & "))"
strQuery = "<LDAP://" & domainDN & ">;" & ldapFilter & _
                             ";distinguishedName,primaryGroupToken;subtree"
objCommand.CommandText = strQuery
Set grpobjectList = objCommand.Execute

count = 0 
While Not grpobjectList.EOF
    groupDN = grpobjectList.Fields("distinguishedName")
    groupRID = grpobjectList.Fields("primaryGroupToken")

    count = count + 1    
    if count = 1 then 
    %>
                <div id="content">
                    <table id="box-table-b" summary="Group">
                        <thead>
                            <tr>
                                <th>Group name</th>
                                <th width=20><b>&nbsp;</b></th>
                                <th>DN</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>
                                    <%Response.Write groupname%>
                                </td>
                                <td width=20><b>&nbsp;</b></td>
                                <td>
                                    <%Response.Write groupDN%>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                    <hr class="clear" />
                </div>
                <div id="content">
                    <table id="box-table-a" summary="GroupMembers">
                        <thead>
                            <tr>
                                <th scope="col">User name</th>
                                <th scope="col" ;width=20><b>&nbsp;</b></th>
                                <th scope="col">User Account</th>
                            </tr>
                            <thead>
                                <tbody>
    <%
    end if 
    
    ldapFilter = "(|(memberOf=" & groupDN & ")(primaryGroupID=" & groupRID & "))"
    strQuery = "<LDAP://" & domainDN & ">;" & ldapFilter & _
                             ";distinguishedName,samAccountName,displayname;subtree"

    objCommand.CommandText = strQuery
    objCommand.Properties("Sort on") = "displayname"    
    Set usrobjectList = objCommand.Execute

    While Not usrobjectList.EOF
        logonName =  usrobjectList.Fields("samAccountName")
        displayName = usrobjectList.Fields("displayname")

    %>
                                        <tr>
                                            <td>
                                                <p>
                                                    <%Response.Write displayName%>
                                                </p>
                                            </td>
                                            <td>&nbsp;</td>
                                            <td>
                                                <p>
                                                    <%Response.Write logonName%>
                                                </p>
                                            </td>
                                        </tr>
                                        <%
                 
        usrobjectList.MoveNext
    Wend

    grpobjectList.MoveNext
Wend
ado.Close

if count <= 0 then
%>
                <div id="content">
                    <table id="box-table-b" summary="Group">
                        <thead>
                            <tr>
                                <th>Group name</th>
                                <th width=20><b>&nbsp;</b></th>
                                <th>Error message.</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr>
                                <td>
                                    <p><%Response.Write groupname%></p>
                                </td>
                                <td width=20>&nbsp;</td>
                                <td>
                                    <p>The group with the name '<%Response.Write groupname%>' could not be found in Active Directory.</p>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                    <hr class="clear" />
                </div>                                        
<%
end if
%>                                        
                    </table>
                    <hr class="clear" />
                    <div id="footer">
                        <div class="left">
                            <p>VDL Nedcar - Information Management</p>
                        </div>
                        <div class="right textright">
                            <p class="show"><a href="#top">Return to top</a></p>
                        </div>
                    </div>
                </div>
</body>

</html>