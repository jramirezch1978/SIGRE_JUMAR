
//<script>
function cii_CBL_DataService_API_version() { return '1.00'; }
function cii_StringReplace(rsStr,rsOldStr,rsNewStr) {
	if (!rsStr) { rsStr = ''; }
	if (!rsOldStr) { rsOldStr = ''; }
	if (!rsNewStr) { rsNewStr = ''; }

	var nLen = rsStr.length;
	var nOldLen = rsOldStr.length;
	var nPos = rsStr.indexOf(rsOldStr);
	
	if (nLen == 0 || nOldLen == 0) { return rsStr;  }
	if (!nPos && (rsOldString != string.substring(0, nOldLen))) { return rsStr; }
	if (nPos == -1) { return rsStr; }

	var sStr = rsStr.substring(0, nPos) + rsNewStr;
	if (nPos + nOldLen < nLen) { sStr += cii_StringReplace(rsStr.substring(nPos + nOldLen,nLen), rsOldStr, rsNewStr); }

	return sStr;
}
function cii_ShowLowestPrice(rsSKU, rsPrefixString, rsPostfixString) {
	if (oCIICBLDataObject[rsSKU.toUpperCase()] && oCIICBLDataObject[rsSKU.toUpperCase()].instockCount && oCIICBLDataObject[rsSKU.toUpperCase()].instockCount > 0) {
		if (!rsPrefixString) { rsPrefixString = ''; } else { rsPrefixString += ' '; }
		if (!rsPostfixString) { rsPostfixString = ''; } else { rsPostfixString = ' ' + rsPostfixString; }
		document.write(rsPrefixString + oCIICBLDataObject[rsSKU.toUpperCase()].lowestInstockPrice + rsPostfixString);
	}
}
function cii_ShowLowestInstockPrice(rsSKU, rsPrefixString, rsPostfixString) {
	if (oCIICBLDataObject[rsSKU.toUpperCase()] && oCIICBLDataObject[rsSKU.toUpperCase()].dealerCount && oCIICBLDataObject[rsSKU.toUpperCase()].dealerCount > 0) {
		if (!rsPrefixString) { rsPrefixString = ''; } else { rsPrefixString += ' '; }
		if (!rsPostfixString) { rsPostfixString = ''; } else { rsPostfixString = ' ' + rsPostfixString; }
		document.write(rsPrefixString + oCIICBLDataObject[rsSKU.toUpperCase()].lowestPrice + rsPostfixString);
	}
}
function cii_ShowCBLButton(rsSKU, roPrimaryLink, roAlternateLink, rnInstance, rnRuleGroupID) {
	var bOutputLink = true;
	var oLink;
	var aOutput = new Array();

	if (!rsSKU) { return; }
	if (!rnRuleGroupID) { rnRuleGroupID = -1; }
	if (!oCIICBLDataObject[rsSKU.toUpperCase()] || !oCIICBLDataObject[rsSKU.toUpperCase()].dealerCount) {
		return;
	}

	if (oCIICBLDataObject[rsSKU.toUpperCase()].dealerCount > 0 && roPrimaryLink) {
		oLink = roPrimaryLink;
	} else if (oCIICBLDataObject[rsSKU.toUpperCase()].dealerCount <= 0 && roAlternateLink) {
		oLink = roAlternateLink;
	} else {
		return;
	}
	if (oLink["linkurl"] && oLink["linkurl"] != '') {
		aOutput[aOutput.length] = '<a href="' + cii_ReplacePlaceHolders(oLink["linkurl"], rsSKU, rnInstance, rnRuleGroupID) + '">';
	} else if (oLink["customlinkurl"] && oLink["customlinkurl"] != '') {
		aOutput[aOutput.length] = cii_ReplacePlaceHolders(oLink["customlinkurl"], rsSKU, rnInstance, rnRuleGroupID);
	} else if (oCIICBLDataObject[rsSKU.toUpperCase()].dealerCount > 0) {
		if (rnRuleGroupID > 0) {
			aOutput[aOutput.length] = '<a href="JavaScript:manu_CDRuleGroupLink(\x27dlink\x27, \x27' + rsSKU + '\x27, \x27' + rnRuleGroupID + '\x27)">';
		} else {
			aOutput[aOutput.length] = '<a href="JavaScript:manu_CDLink(\x27dlink\x27, \x27' + rsSKU + '\x27)">';
		}
	} else {
		bOutputLink = false;
	}
	if (oLink["imageurl"] && oLink["imageurl"] != '') {
		aOutput[aOutput.length] = '<img src="' + oLink["imageurl"] + '" border="0"';
		oImage = new Image();
		oImage.src = oLink["imageurl"];
		if (oImage.width) {
			aOutput[aOutput.length] = ' height="' + oImage.height + '" width="' + oImage.width + '"';
		}
		if (oLink["onmouseover"] && oLink["onmouseover"] != '') {
			aOutput[aOutput.length] = ' onMouseOver="' + oLink["onmouseover"] + '"';
		}
		if (oLink["onmouseout"] && oLink["onmouseout"] != '') {
			aOutput[aOutput.length] = ' onMouseOut="' + oLink["onmouseout"] + '"';
		}
		aOutput[aOutput.length] = ' alt="' + oLink["alt"] + '" />';
	} else if (oLink["customimagehtml"] && oLink["customimagehtml"] != '') {
		aOutput[aOutput.length] = cii_ReplacePlaceHolders(oLink["customimagehtml"], rsSKU, rnInstance, rnRuleGroupID);
	} else if (oLink["linktext"]) {
		aOutput[aOutput.length] = cii_ReplacePlaceHolders(oLink["linktext"], rsSKU, rnInstance, rnRuleGroupID);
	}
	if (bOutputLink) {
		aOutput[aOutput.length] = '</a>';
	}

	document.write(aOutput.join(''));
}
function cii_ReplacePlaceHolders(rsString, rsSKU, rnInstance, rnRuleGroupID) {

	if (!rsString) { rsString = ''; }
	if (!rsSKU) { rsSKU = ''; }
	if (!rnInstance) { rnInstance = 1; }
	if (!rnRuleGroupID) { rnRuleGroupID = ''; }
	rsString = cii_StringReplace(rsString, "<sku />", rsSKU);
	rsString = cii_StringReplace(rsString, "<sku/>", rsSKU);
	rsString = cii_StringReplace(rsString, "<sku>", rsSKU);
	rsString = cii_StringReplace(rsString, "<instance>", rnInstance);
	rsString = cii_StringReplace(rsString, "<instance/>", rnInstance);
	rsString = cii_StringReplace(rsString, "<instance />", rnInstance);
	rsString = cii_StringReplace(rsString, "<rgid>", rnRuleGroupID);
	rsString = cii_StringReplace(rsString, "<rgid/>", rnRuleGroupID);
	rsString = cii_StringReplace(rsString, "<rgid />", rnRuleGroupID);

	return rsString;
}
//</script>