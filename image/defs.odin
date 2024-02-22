package image

ImageSize :: [2]u32;

IMAGE_INFO_IMAGE_TYPE_UUID_MASK :: 0x0F;
IMAGE_INFO_PIXEL_TYPE_UUID_MASK :: 0xF0;

ImageInfoUUID :: distinct u16;
ImageInfoInvalid :: ~ImageInfoUUID(1);

ImageTypeUUID :: ImageInfoUUID;
BGR_UUID  :: ImageTypeUUID(1);
RGBA_UUID :: ImageTypeUUID(2);

PixelTypeUUID :: ImageInfoUUID;
/* 8 bit pixels */
UINT8_UUID  :: PixelTypeUUID(1);
UNORM8_UUID :: PixelTypeUUID(2);
SNORM8_UUID :: PixelTypeUUID(7);
SINT8_UUID  :: PixelTypeUUID(8);
/* 16 bit pixels */
UINT16_UUID  :: PixelTypeUUID(3);
UNORM16_UUID :: PixelTypeUUID(4);
SNORM16_UUID :: PixelTypeUUID(9);
SINT16_UUID  :: PixelTypeUUID(10);
/* 32 bit pixels */
UINT32_UUID  :: PixelTypeUUID(5);
UNORM32_UUID :: PixelTypeUUID(6);
SNORM32_UUID :: PixelTypeUUID(11);
SINT32_UUID  :: PixelTypeUUID(12);