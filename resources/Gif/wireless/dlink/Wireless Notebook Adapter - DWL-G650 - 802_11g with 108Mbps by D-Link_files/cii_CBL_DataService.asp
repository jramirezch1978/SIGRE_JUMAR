
/*
<!--
<items>
<item type="info" PID="10738630" ProductType="ufp" CID="0">
<fact name="Manufacturer" id="2491"><![CDATA[Dlink]]></fact>
<fact name="Name" id="2481"><![CDATA[D-Link Air Plus Xtreme G 54Mbps Wireless Cardbus Adapter]]></fact>
<fact name="Model Number" id="2493"><![CDATA[DWL-G650]]></fact>
<fact name="Price" id="2495"><![CDATA[48.91]]></fact>
</item>
</items>
-->

*/
//<script>
if (typeof(oCIICBLDataObject) == 'undefined') {
	oCIICBLDataObject = new Object();
}
oCIICBLDataObject["DWL-G650"] = new Object();
oCIICBLDataObject["DWL-G650"].sku = 'DWL-G650';
oCIICBLDataObject["DWL-G650"].itemID = '10738630';
oCIICBLDataObject["DWL-G650"].lowestPrice = '$48.91';
oCIICBLDataObject["DWL-G650"].dealerCount = '16';
oCIICBLDataObject["DWL-G650"].instockCount = '16';
oCIICBLDataObject["DWL-G650"].lowestInstockPrice = '$48.91';
//</script>

var cii_sBase="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
var cii_dDate=new Date();
var cii_nRand=Math.floor((cii_dDate.getTime()-946875600000)/604800000);
var cii_sRValue=cii_sBase.charAt((cii_dDate.getYear()<2000?cii_dDate.getFullYear():cii_dDate.getYear())-2000)+cii_sBase.charAt(cii_dDate.getMonth()+1)+cii_sBase.charAt(cii_dDate.getDate())+cii_sBase.charAt(cii_dDate.getHours())+cii_sBase.charAt(cii_dDate.getMinutes())+cii_sBase.charAt(cii_dDate.getSeconds())+cii_sBase.charAt((cii_nRand-(cii_nRand%16))/16)+cii_sBase.charAt(cii_nRand%16);
if (typeof(oCIILogging)=='undefined') { oCIILogging=new Object(); }
oCIILogging[cii_sRValue]=new Image();
oCIILogging[cii_sRValue].src='http://dlink.links.origin.channelintelligence.com/pages/wl.asp?nCTID=11&nSCID=0&nIID=10738630&nICnt=16&nRGID=0&sManufacturer=Dlink&sModelNumber=DWL%2DG650&sModelNumber=&nCMPID=0&sSKU=DWL%2DG650&nRadius=15&nRID=0&nCID=0&sRnd='+cii_sRValue;