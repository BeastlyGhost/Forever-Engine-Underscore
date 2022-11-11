package;

import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class ModManager
{
	inline public static function getModRoot(key:String = ''):String
	{
		return 'mods/$key';
	}

	public static function getModFolders():Array<String>
	{
		var modFolders:Array<String> = [];
		var modRoot:String = getModRoot();

		if (sys.FileSystem.exists(modRoot))
		{
			for (mod in sys.FileSystem.readDirectory(modRoot))
			{
				/*
					ok so from what i've been told, this basically formats the path as "mods/folder" instead of just "folder"
					it's kind of a way of making the code cleaner
					but it's no different than doing something like var str:String = modRoot + '/' + mod; for instance
				 */
				var root = haxe.io.Path.join([modRoot, mod]);
				if (sys.FileSystem.isDirectory(root) && !modFolders.contains(mod))
				{
					if (!mod.contains('.'))
						modFolders.push(mod);
				}
			}
		}
		return modFolders;
	}

	public static function getModFile(file:String, ?type:AssetType)
	{
		for (folder in getModFolders())
		{
			try
			{
				var returnFolder:String = '${getModRoot(folder)}/$file';
				if (!sys.FileSystem.exists(returnFolder))
					returnFolder = base.CoolUtil.swapSpaceDash(returnFolder);
				return returnFolder;
			}
			catch (e)
			{
				// trace('$modFile is null, trying method 2');
				try
				{
					var returnFolder:String = '${getModRoot(folder)}/$file';
					if (OpenFlAssets.exists(returnFolder, type))
						return returnFolder;
				}
				catch (e)
				{
					// trace('$file is null');
					return null;
				}
			}
		}
		// trace('$file is null');
		return null;
	}
}
