// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.assets;

import openfl.utils.ByteArray;

import starling.textures.AtfData;
import starling.textures.Texture;

/** This AssetFactory creates texture assets from ATF files. */
class AtfTextureFactory extends AssetFactory
{
	/** Creates a new instance. */
	public function new()
	{
		super();
		addExtensions(["atf"]); // not used, actually, since we can parse the ATF header, anyway.
	}

	/** @inheritDoc */
	override public function canHandle(reference:AssetReference):Bool
	{
		return (Std.is(reference.data, #if commonjs ByteArray #else ByteArrayData #end) && AtfData.isAtfData(cast reference.data));
	}

	/** @inheritDoc */
	override public function create(reference:AssetReference, helper:AssetFactoryHelper,
									onComplete:String->Dynamic->Void, onError:String->Void):Void
	{
		var onReloadError:String->Void = null;
		var createTexture:Void->Void = null;
		
		onReloadError = function (error:String):Void
		{
			helper.log("Texture restoration failed for " + reference.url + ". " + error);
			helper.onEndRestore();
		}
		
		createTexture = function ():Void
		{
			var texture:Texture = null;
			
			reference.textureOptions.onReady = function(_):Void
			{
				onComplete(reference.name, texture);
			};
			
			texture = Texture.fromData(reference.data, reference.textureOptions);
			var url:String = reference.url;
			
			if (url != null)
			{
				texture.root.onRestore = function(_):Void
				{
					helper.onBeginRestore();
					helper.loadDataFromUrl(url, function(data:ByteArray, ?mimeType:String):Void
					{
						helper.executeWhenContextReady(function():Void
						{
							texture.root.uploadAtfData(data);
							helper.onEndRestore();
						});
					}, onReloadError);
				};
			}
		}

		helper.executeWhenContextReady(createTexture);
	}
}