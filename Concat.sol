import "github.com/Arachnid/solidity-stringutils/strings.sol";
    
    library Concat {
    using strings for *;
    //string s3 = ",";

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
	
	function getStringList (string[] list) internal returns (string listString) {
        for(uint i = 0; i < list.length; i++) {
            listString = concatList(listString, list[i]);
        }	
    }
	}