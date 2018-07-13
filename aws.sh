#!/bin/bash

function tagResource(){
    resourceID=$1; shift
    [ -z $resourceID ] && return
    ts=`date +%s`
    aws ec2 create-tags --resource $resourceID --tags Key=Name,Value=JimmyJames_${ts}
}

######################################################################
# VPCs

function descVPC(){
    vpcID=$1; shift
    [ -z $vpcID ] && return

    result=`aws ec2 describe-vpcs | jq ".Vpcs[] | select (.VpcId==\"$vpcID\")"`
    vpcID=`echo $result | jq -r .VpcId`
    #cidrBlockAssociationSet=`echo $result | jq -r .CidrBlockAssociationSet[]?.AssociationId`

    igws=`aws ec2 describe-internet-gateways`
    igwID=`echo $igws | jq -r ".InternetGateways[] | select(.Attachments[].VpcId == \"$vpcID\") | .InternetGatewayId "`

    routeTables=`aws ec2 describe-route-tables`
    rtbID=`echo $routeTables | jq -r ".RouteTables[] | select(.VpcId == \"$vpcID\" ) | .RouteTableId"`

    subnets=`aws ec2 describe-subnets`
    subnet=`echo $subnets | jq -r ".Subnets[] | select(.VpcId == \"$vpcID\")" `
    subnetID=`echo $subnet | jq -r .SubnetId`
    availabilityZone=`echo $subnet | jq -r .AvailabilityZone`

    # TODO get ip address if possible

    # aws ec2 describe-security-groups | jq -r ".SecurityGroups[] | select(.VpcId == \"vpc-0d61a27126306ae0e\") | .GroupId + \" \" + .GroupName"
    echo $vpcID
    echo $igwID
    echo $rtbID
    echo $subnetID
    echo $availabilityZone
}

function createVPC(){
    result=`aws ec2 create-vpc --cidr-bloc "10.0.0.0/16"`
    vpcID=`echo $result | jq -r .Vpc.VpcId`
    tagResource $vpcID
    echo $vpcID
}

function getMyVPCs(){
    allVPCs=`aws ec2 describe-vpcs`
    for i in `echo $allVPCs | jq -r ' .Vpcs[] | .VpcId + "." + .Tags[]?.Value'`
    do
	vpcID=`echo $i | cut -d '.' -f1`
	name=`echo $i | cut -d '.' -f2`

	# The == comparison operator behaves differently within a double-brackets
	# test than within single brackets.
	if [[ $name == JimmyJames* ]]
	then
	   echo $vpcID
	fi
    done
}

function deleteMyVPCs(){
    for vpcID in `getMyVPCs`
    do
	subnetID=`aws ec2 describe-subnets | jq -r ".Subnets[] | select(.VpcId==\"$vpcID\") | .SubnetId"`
	echo removing $subnetID
	deleteSubnet $subnetID
	echo removing $vpcID
	aws ec2 delete-vpc --vpc-id $vpcID
    done
}

function descIGW(){
    igwID=$1; shift
    [ -z $igwID ] && return
    aws ec2 describe-internet-gateways | jq ".InternetGateways[] | select (.InternetGatewayId==\"$igwID\")"
}

function getMyIGWs(){
    allIGWs=`aws ec2 describe-internet-gateways`
    for i in `echo $allIGWs | jq -r ' .InternetGateways[] | .InternetGatewayId + "." + .Tags[].Value'`
    do
	igwID=`echo $i | cut -d '.' -f1`
	name=`echo $i | cut -d '.' -f2`
	if [[ $name == JimmyJames* ]]
	then
	    echo $igwID
	fi
    done
}

function createIGW(){
    result=`aws ec2 create-internet-gateway`
    igwID=`echo $result | jq -r .InternetGateway.InternetGatewayId`
    tagResource $igwID
    echo $igwID
}

function deleteMyIGWs(){
    for i in `getMyIGWs`
    do
	echo removing $i
	aws ec2 delete-internet-gateway --internet-gateway-id $i
    done
}

function detachIGW(){
    igwID=$1; shift
    [ -z $igwID ] && return
    vpcID=`descIGW $igwID | jq -r '.Attachments[] | .VpcId'`
    [ -z $vpcID ] && return
    echo detaching $igwID from $vpcID
    aws ec2 detach-internet-gateway --vpc-id $vpcID --internet-gateway-id $igwID
}

function descRoutesTables(){
    result=`aws ec2 describe-route-tables`
    echo $result | jq .
}

function createSubnet(){
    vpcID=$1; shift
    [ -z $vpcID ] && echo skipping subnet creation && return
    result=`aws ec2 create-subnet --cidr-block '10.0.0.0/16' --vpc-id $vpcID --availability-zone us-west-1b`
    subnetID=`echo $result | jq -r .Subnet.SubnetId`
    echo $subnetID
}

function deleteSubnet(){
    subnetID=$1; shift
    [ -z $subnetID ] && return
    aws ec2 delete-subnet --subnet-id $subnetID
}

function spinUp(){
    doExport=0
    [ "$1" = '-e' ] && doExport=1 && shift

    vpcID=`createVPC`
    igwID=`createIGW`
    aws ec2 attach-internet-gateway --vpc-id $vpcID --internet-gateway-id $igwID
    routeTable=`aws ec2 describe-route-tables | jq ".RouteTables[] | select(.VpcId==\"$vpcID\")"`
    routeTableID=`echo $routeTable | jq -r .RouteTableId`
    aws ec2 create-route --route-table-id $routeTableID --destination-cidr-block '0.0.0.0/0' --gateway-id $igwID > /dev/null
    subnetID=`createSubnet $vpcID`
    if [ $doExport -eq 1 ]
    then
	printf "export vpcID=$vpcID; export igwID=$igwID; export routeTableID=$routeTableID; export subnetID=$subnetID" | pbcopy
	printf "exports of the following are in the system clipboard\n\n"
    fi
    echo "       vpcID: $vpcID"
    echo "       igwID: $igwID"
    echo "routeTableID: $routeTableID"
    echo "    subnetID: $subnetID"
}

function tearDown(){
    for i in `getMyIGWs`
    do
	detachIGW $i
    done
    deleteMyIGWs
    # for i in `getMyVPCs`
    # do

    # done
    deleteMyVPCs
}


# this is for docker-machine generated ec2 instance
function exposePort(){
    machineName=$1; shift
    [ -z $machineName ] && echo please provide machine name && return
    port=$1; shift
    [ -z $port ] && echo please provide port && return

    groupID=`docker-machine inspect $machineName | jq -r .Driver.SecurityGroupIds[]`
    aws ec2 authorize-security-group-ingress --group-id $groupID --port $port --cidr "0.0.0.0/0" --protocol=tcp
}



$@
