pragma solidity ^0.4.10;
//import './strings.sol'; // best way to do an external libray that isn't on npm
 import "github.com/Arachnid/solidity-stringutils/strings.sol";
    
library ConcatStrings {
    using strings for *;

    function concatList(string s1, string s2) internal returns (string) {
        bytes memory string1 = bytes(s1);
        string memory s4;
        if (string1.length == 0) {
            s4 = "";
        } else {
            s4 = s1.toSlice().concat(",".toSlice());
        }
        return s4.toSlice().concat(s2.toSlice());
    }

    function concatStrings(string s1, string s2, string s3) internal returns (string) {
        bytes memory string1 = bytes(s1);
        string memory s4;
        if (string1.length == 0) {
            s4 = "";
        } else {
            s4 = s1.toSlice().concat(s3.toSlice());
        }
        return s4.toSlice().concat(s2.toSlice());
    }
	
	function getStringList (string[] list) internal returns (string listString) {
        for(uint i = 0; i < list.length; i++) {
            listString = concatList(listString, list[i]);
        }	
    }
}
